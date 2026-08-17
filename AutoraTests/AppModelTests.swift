import Foundation
import Testing
@testable import Autora

struct AppModelTests {
    private func model(
        listings: [Listing],
        now: TimeInterval = 1_000_000,
        session: UserSession = .guest
    ) -> AppModel {
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let seed = SeedFile(listings: listings, chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        let model = AppModel(seed: seed, defaults: defaults, now: { now })
        model.session = session
        return model
    }

    @Test func reportRecordsReason() {
        let app = model(listings: [listingFixture(id: "a")])
        #expect(app.reports.isEmpty)
        app.report(listingID: "a", reason: "fraud")
        #expect(app.reports.count == 1)
        #expect(app.reports[0].listingID == "a")
        #expect(app.reports[0].reason == "fraud")
    }

    @Test func filteredHidesExpiredListings() {
        let fresh = listingFixture(id: "fresh", bumpedAt: 1_000_000)
        let stale = listingFixture(id: "stale", bumpedAt: 1_000_000 - BumpPolicy.lifetime)
        let app = model(listings: [fresh, stale], now: 1_000_000)
        #expect(app.filtered.map(\.id) == ["fresh"])
    }

    @Test func applySavedSearchCopiesFullCriteria() {
        var criteria = SearchCriteria()
        criteria.make = "Volkswagen"
        criteria.model = "Passat"
        criteria.generation = "B8"
        criteria.yearFrom = 2016
        criteria.priceTo = 20000
        criteria.city = "Минск"
        let search = SavedSearch.from(criteria: criteria, id: "ss")
        let app = model(listings: [])
        app.applySavedSearch(search)
        #expect(app.criteria.generation == "B8")
        #expect(app.criteria.yearFrom == 2016)
        #expect(app.criteria.make == "Volkswagen")
    }

    @Test func openSavedSearchSwitchesToSearchTab() {
        var criteria = SearchCriteria()
        criteria.make = "Audi"
        let search = SavedSearch.from(criteria: criteria, id: "ss")
        let app = model(listings: [])
        app.selectedTab = .favorites
        app.openSavedSearch(search)
        #expect(app.selectedTab == .search)
        #expect(app.criteria.make == "Audi")
    }

    @Test func selectMakeClearsModelAndGeneration() {
        let app = model(listings: [listingFixture(make: "VW", model: "Passat", generation: "B8")])
        app.selectMake("VW")
        app.selectModel("Passat")
        app.selectGeneration("B8")
        #expect(app.criteria.generation == "B8")
        app.selectMake("Audi")
        #expect(app.criteria.make == "Audi")
        #expect(app.criteria.model == nil)
        #expect(app.criteria.generation == nil)
        app.selectMake("Audi")
        #expect(app.criteria.make == nil)
    }

    @Test func saveCurrentSearchPersists() {
        let app = model(listings: [])
        app.criteria.make = "BMW"
        let saved = app.saveCurrentSearch()
        #expect(app.savedSearches.contains(saved))
        let reloaded = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1 }
        )
        #expect(reloaded.savedSearches.contains { $0.criteria.make == "BMW" })
    }

    @Test func startChatRequiresSignIn() {
        let listing = listingFixture(id: "a", sellerId: "other")
        let app = model(listings: [listing])
        #expect(throws: ChatStartError.needAuth) {
            try app.startChat(for: listing)
        }
    }

    @Test func startChatRejectsOwnListing() {
        let listing = listingFixture(id: "a", sellerId: "me-local")
        let app = model(
            listings: [listing],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        #expect(throws: ChatStartError.cannotMessageSelf) {
            try app.startChat(for: listing)
        }
    }

    @Test func startChatCreatesThreadWhenSignedIn() throws {
        let listing = listingFixture(id: "a", sellerId: "other")
        let app = model(
            listings: [listing],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        let id = try app.startChat(for: listing)
        #expect(app.chats.contains { $0.id == id && $0.listingId == "a" })
    }

    @Test func blockPersistsAcrossReload() {
        let app = model(listings: [listingFixture(id: "a", sellerId: "bad")])
        app.block(sellerID: "bad")
        #expect(app.filtered.isEmpty)
        let reloaded = AppModel(
            seed: SeedFile(listings: [listingFixture(id: "a", sellerId: "bad")], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1 }
        )
        #expect(reloaded.blockedSellerIDs.contains("bad"))
    }

    @Test func missingSeedSetsLoadError() {
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let app = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 },
            seedMissing: true
        )
        #expect(app.loadError != nil)
    }

    @Test func pendingDeepLinkOpensListing() {
        let listing = listingFixture(id: "lst-000")
        let app = model(listings: [listing])
        app.handleDeepLink(URL(string: "autora://listing/lst-000")!)
        #expect(app.pendingListingID == "lst-000")
        #expect(app.selectedTab == .search)
    }

    @Test func applyCatalogKeepsPublishedListing() throws {
        let seedListing = listingFixture(id: "seed-a", bumpedAt: 1_000_000)
        let app = model(
            listings: [seedListing],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        var draft = ListingDraft.sample
        draft.photoURLs = ["file:///tmp/a.jpg"]
        let mine = try draft.makeListing(id: "mine-1", seller: app.session.profile!, now: 1_000_000)
        try app.publishDraft(mine)
        app.applyCatalog(
            SeedFile(listings: [seedListing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        )
        #expect(app.listings.contains { $0.id == "mine-1" })
        #expect(app.myListings.contains { $0.id == "mine-1" })
        #expect(app.filtered.contains { $0.id == "mine-1" })
    }

    @Test func applyCatalogKeepsUserChatAndSeedUnread() throws {
        let listing = listingFixture(id: "a", sellerId: "other")
        let seedChat = ChatThread(
            id: "chat-001",
            listingId: "seed",
            listingTitle: "S",
            peerName: "P",
            unread: 2,
            messages: []
        )
        let app = model(
            listings: [listing],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        app.chats = [seedChat]
        let id = try app.startChat(for: listing)
        app.applyCatalog(
            SeedFile(listings: [listing], chats: [seedChat], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        )
        #expect(app.chats.contains { $0.id == id })
        #expect(app.chats.contains { $0.id == "chat-001" && $0.unread == 2 })
    }

    @Test func publishedListingSurvivesReload() throws {
        let app = model(
            listings: [listingFixture(id: "seed-a")],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        var draft = ListingDraft.sample
        draft.photoURLs = ["file:///tmp/a.jpg"]
        try app.publishDraft(try draft.makeListing(id: "mine-1", seller: app.session.profile!, now: 1_000_000))
        let reloaded = AppModel(
            seed: SeedFile(listings: [listingFixture(id: "seed-a")], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1_000_000 }
        )
        #expect(reloaded.myListings.contains { $0.id == "mine-1" })
        #expect(reloaded.listings.contains { $0.id == "mine-1" })
        #expect(reloaded.session.profile?.id == "me-local")
    }

    @Test func showUSDAndCompareSurviveReload() {
        let app = model(listings: [listingFixture(id: "a")])
        app.showUSD = true
        app.toggleCompare("a")
        let reloaded = AppModel(
            seed: SeedFile(listings: [listingFixture(id: "a")], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1 }
        )
        #expect(reloaded.showUSD)
        #expect(reloaded.compareIDs == ["a"])
    }

    @Test func chatsSurviveReload() throws {
        let listing = listingFixture(id: "a", sellerId: "other")
        let app = model(
            listings: [listing],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        let id = try app.startChat(for: listing)
        app.sendMessage(threadID: id, text: "привет")
        let reloaded = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1 }
        )
        #expect(reloaded.chats.contains { $0.id == id && $0.messages.contains { $0.text == "привет" } })
    }

    @Test func markThreadReadClearsUnreadAndPersists() {
        let thread = ChatThread(
            id: "chat-001",
            listingId: "a",
            listingTitle: "S",
            peerName: "P",
            unread: 2,
            messages: []
        )
        let app = model(listings: [listingFixture(id: "a")])
        app.chats = [thread]
        #expect(app.unreadCount == 2)
        app.markThreadRead("chat-001")
        #expect(app.unreadCount == 0)
        let reloaded = AppModel(
            seed: SeedFile(listings: [listingFixture(id: "a")], chats: [thread], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1 }
        )
        #expect(reloaded.chats.first { $0.id == "chat-001" }?.unread == 0)
    }

    @Test func listingDraftAutosavesAndClearsOnPublish() throws {
        let app = model(
            listings: [],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        app.listingDraft.make = "Mazda"
        app.listingDraft.model = "6"
        app.listingDraft.priceBYN = 9000
        app.listingDraft.photoURLs = ["file:///tmp/a.jpg"]
        let reloaded = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1 }
        )
        #expect(reloaded.listingDraft.make == "Mazda")
        try app.publishDraft(try app.listingDraft.makeListing(id: "mine-1", seller: app.session.profile!, now: 1))
        app.clearListingDraft()
        #expect(app.listingDraft.make.isEmpty)
        let afterPublish = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1 }
        )
        #expect(afterPublish.listingDraft.make.isEmpty)
    }

    @Test func startChatWritesParticipantIds() throws {
        let listing = listingFixture(id: "a", sellerId: "other")
        let app = model(
            listings: [listing],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        let id = try app.startChat(for: listing)
        #expect(app.chats.first { $0.id == id }?.participantIds == ["me-local", "other"])
    }

    @Test func setListingStatusSoldHidesFromFeedAndPersists() throws {
        let app = model(
            listings: [],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        var draft = ListingDraft.sample
        draft.photoURLs = ["file:///tmp/a.jpg"]
        try app.publishDraft(try draft.makeListing(id: "mine-1", seller: app.session.profile!, now: 1_000_000))
        app.setListingStatus("mine-1", .sold)
        #expect(app.myListings.first?.status == .sold)
        #expect(!app.filtered.contains { $0.id == "mine-1" })
        app.setListingStatus("mine-1", .active)
        #expect(app.filtered.contains { $0.id == "mine-1" })
        let reloaded = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1_000_000 }
        )
        #expect(reloaded.myListings.first { $0.id == "mine-1" }?.status == .active)
    }

    @Test func toggleFavoriteUpdatesCount() {
        let app = model(listings: [listingFixture(id: "a")])
        app.toggleFavorite("a")
        #expect(app.listings.first?.favoritesCount == 1)
        app.toggleFavorite("a")
        #expect(app.listings.first?.favoritesCount == 0)
    }

    @Test func markViewedIncrementsViews() {
        let app = model(listings: [listingFixture(id: "a")])
        app.markViewed("a")
        #expect(app.listings.first?.views == 1)
        app.markViewed("a")
        #expect(app.listings.first?.views == 2)
    }

    @Test func recordPhoneRevealIncrements() {
        let app = model(listings: [listingFixture(id: "a")])
        app.recordPhoneReveal(listingID: "a")
        #expect(app.listings.first?.phoneReveals == 1)
    }

    @Test func deleteSavedSearchRemovesUserSearch() {
        let app = model(listings: [])
        app.criteria.make = "BMW"
        let saved = app.saveCurrentSearch()
        app.deleteSavedSearch(saved.id)
        #expect(!app.savedSearches.contains { $0.id == saved.id })
    }

    @Test func deleteSeedSearchStaysGoneAfterReload() {
        var criteria = SearchCriteria()
        criteria.make = "Audi"
        let seedSearch = SavedSearch.from(criteria: criteria, id: "ss-audi")
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let seed = SeedFile(
            listings: [],
            chats: [],
            savedSearches: [seedSearch],
            fx: FXRate(usdBYN: 2.99)
        )
        let app = AppModel(seed: seed, defaults: defaults, now: { 1 })
        #expect(app.savedSearches.contains { $0.id == "ss-audi" })
        app.deleteSavedSearch("ss-audi")
        let reloaded = AppModel(seed: seed, defaults: defaults, now: { 1 })
        #expect(!reloaded.savedSearches.contains { $0.id == "ss-audi" })
    }

    @Test func updateProfileCopiesPhoneToMyListings() throws {
        let app = model(
            listings: [],
            session: .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        )
        var draft = ListingDraft.sample
        draft.photoURLs = ["file:///tmp/a.jpg"]
        try app.publishDraft(try draft.makeListing(id: "mine-1", seller: app.session.profile!, now: 1))
        app.updateProfile(name: "Борис", phone: "+375291112233")
        #expect(app.session.profile?.name == "Борис")
        #expect(app.myListings.first?.sellerPhone == "+375291112233")
        #expect(app.listings.first { $0.id == "mine-1" }?.sellerName == "Борис")
    }

    @Test func clearCompareEmptiesSet() {
        let app = model(listings: [listingFixture(id: "a")])
        app.toggleCompare("a")
        app.clearCompare()
        #expect(app.compareIDs.isEmpty)
    }
}

struct ListingDraftTests {
    @Test func emptyHasNoMakeOrPrice() {
        let draft = ListingDraft()
        #expect(draft.make.isEmpty)
        #expect(draft.model.isEmpty)
        #expect(draft.priceBYN == 0)
        #expect(draft.photoURLs.isEmpty)
    }

    @Test func canLeavePhotoStepRequiresPhoto() {
        var draft = ListingDraft()
        #expect(!draft.canLeave(step: 0))
        draft.photoURLs = ["file:///tmp/a.jpg"]
        #expect(draft.canLeave(step: 0))
    }

    @Test func canLeaveSpecAndPriceSteps() {
        var draft = ListingDraft()
        draft.photoURLs = ["file:///tmp/a.jpg"]
        #expect(!draft.canLeave(step: 2))
        draft.make = "Mazda"
        draft.model = "6"
        #expect(draft.canLeave(step: 2))
        #expect(!draft.canLeave(step: 3))
        draft.priceBYN = 9000
        #expect(draft.canLeave(step: 3))
        #expect(draft.canLeave(step: 1))
    }

    @Test func rejectsEmptyPhotos() {
        var draft = ListingDraft.sample
        draft.photoURLs = []
        #expect(throws: AppError.needPhoto) {
            try draft.makeListing(
                id: "mine-1",
                seller: UserProfile(id: "me", name: "Вы", phone: "+37529", isOwner: false),
                now: 1
            )
        }
    }

    @Test func usesProvidedMileageAndBodyNotHardcoded() throws {
        var draft = ListingDraft.sample
        draft.mileageKm = 45000
        draft.body = "универсал"
        draft.transmission = "механика"
        draft.photoURLs = ["file:///tmp/a.jpg"]
        let listing = try draft.makeListing(
            id: "mine-1",
            seller: UserProfile(id: "me", name: "Вы", phone: "+37529", isOwner: false),
            now: 10
        )
        #expect(listing.mileageKm == 45000)
        #expect(listing.body == "универсал")
        #expect(listing.transmission == "механика")
        #expect(listing.photoURLs == ["file:///tmp/a.jpg"])
        #expect(listing.isDemo == false)
        #expect(!listing.photoURLs.contains { $0.contains("unsplash") })
    }
}

struct DeepLinkTests {
    @Test func parsesListingURL() {
        #expect(AutoraDeepLink.listingID(from: URL(string: "autora://listing/lst-000")!) == "lst-000")
        #expect(AutoraDeepLink.listingID(from: URL(string: "https://example.com")!) == nil)
        #expect(AutoraDeepLink.listingID(from: URL(string: "autora://other/x")!) == nil)
    }
}

struct PhoneClipboardTests {
    @Test func ttlIsSixtySeconds() {
        #expect(PhoneClipboard.ttl == 60)
    }
}
