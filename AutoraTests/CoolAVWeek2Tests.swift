import Foundation
import Testing
@testable import Autora

struct ListingDraftVINTests {
    @Test func emptyVINCanLeaveStep() {
        var draft = ListingDraft()
        draft.vin = ""
        #expect(draft.canLeave(step: 1))
        #expect(draft.leaveError(for: 1) == nil)
    }

    @Test func partialVINBlocksStep() {
        var draft = ListingDraft()
        draft.vin = "WVWZZZ"
        #expect(!draft.canLeave(step: 1))
        #expect(draft.leaveError(for: 1) == .needVIN)
    }

    @Test func seventeenCharVINCanLeave() {
        var draft = ListingDraft()
        draft.vin = "WVWZZZ00000000000"
        #expect(draft.canLeave(step: 1))
        #expect(ListingDraft.normalizedVIN(" wv-wzzz00000000000 ") == "WVWZZZ00000000000")
    }

    @Test func makeListingRejectsPartialVIN() {
        var draft = ListingDraft.sample
        draft.photoURLs = ["file:///tmp/a.jpg"]
        draft.vin = "SHORT"
        #expect(throws: AppError.needVIN) {
            try draft.makeListing(
                id: "mine-1",
                seller: UserProfile(id: "me", name: "Вы", phone: "+37529", isOwner: false),
                now: 1
            )
        }
    }
}

struct ListingDraftValuationTests {
    @Test func suggestedQuoteUsesDraftCondition() {
        var draft = ListingDraft()
        draft.make = "Geely"
        draft.year = 2022
        draft.mileageKm = 45_000
        draft.valuationCondition = .excellent
        let excellent = draft.suggestedQuote(usdBYN: 2.99, nowYear: 2026)
        draft.valuationCondition = .good
        let good = draft.suggestedQuote(usdBYN: 2.99, nowYear: 2026)
        #expect(excellent.usd > good.usd)
        #expect(good.usd == 21_853)
    }
}

struct ListingDraftEditTests {
    @Test func fromListingAndApplyKeepsStatsAndUpdatesPrice() throws {
        var listing = listingFixture(
            id: "mine-1",
            make: "Mazda",
            model: "6",
            price: 12_000,
            photoURLs: ["file:///tmp/a.jpg"]
        )
        listing.views = 44
        listing.favoritesCount = 3
        listing.phoneReveals = 2
        listing.description = "старое"
        listing.createdAt = 100
        listing.bumpedAt = 200
        listing.isTop = true
        listing.status = .active

        var draft = ListingDraft.from(listing)
        draft.priceBYN = 9_000
        draft.description = "обновлено"
        draft.photoURLs = ["file:///tmp/b.jpg"]
        draft.equipment = ["Apple CarPlay и Android Auto"]

        let saved = try draft.apply(
            onto: listing,
            seller: UserProfile(id: "me", name: "Вы", phone: "+37529", isOwner: false),
            now: 999
        )
        #expect(saved.id == "mine-1")
        #expect(saved.priceBYN == 9_000)
        #expect(saved.description == "обновлено")
        #expect(saved.photoURLs == ["file:///tmp/b.jpg"])
        #expect(saved.views == 44)
        #expect(saved.favoritesCount == 3)
        #expect(saved.phoneReveals == 2)
        #expect(saved.createdAt == 100)
        #expect(saved.bumpedAt == 200)
        #expect(saved.isTop)
        #expect(saved.status == .active)
        #expect(saved.equipment == ["Apple CarPlay и Android Auto"])
        #expect(ListingTrust.showsSyntheticEquipment(saved))
        #expect(!ListingTrust.showsSyntheticEquipment(listingFixture()))
    }

    @Test func makeListingWritesEquipmentAndNormalizedVIN() throws {
        var draft = ListingDraft.sample
        draft.photoURLs = ["file:///tmp/a.jpg"]
        draft.vin = "wvwzzz00000000000"
        draft.equipment = ["Премиум акустика"]
        let listing = try draft.makeListing(
            id: "mine-1",
            seller: UserProfile(id: "me", name: "Вы", phone: "+37529", isOwner: false),
            now: 1
        )
        #expect(listing.vin == "WVWZZZ00000000000")
        #expect(listing.equipment == ["Премиум акустика"])
    }

    @Test func missingEquipmentKeyDecodesAsEmpty() throws {
        let json = """
        {"id":"a","sellerId":"s","sellerName":"S","sellerPhone":"+375","sellerListingCount":1,"make":"VW","model":"Passat","year":2018,"priceBYN":100,"mileageKm":1,"body":"седан","fuel":"бензин","transmission":"автомат","drivetrain":"передний","engineLiters":2,"powerHp":150,"city":"Минск","region":"Минская","condition":"used","registered":true,"customsCleared":true,"wheel":"left","hasPhotos":false,"bargaining":false,"exchange":false,"forParts":false,"damaged":false,"isTop":false,"isDemo":true,"status":"active","photoURLs":[],"description":"","views":0,"favoritesCount":0,"phoneReveals":0,"bumpedAt":1,"createdAt":1}
        """
        let listing = try JSONDecoder().decode(Listing.self, from: Data(json.utf8))
        #expect((listing.equipment ?? []).isEmpty)
    }
}

struct ChatOfferTests {
    @Test func priceOfferIncludesMakeModelAndTarget() {
        let text = ChatDraft.priceOffer(make: "Geely", model: "Monjaro", targetUSD: 9_500)
        #expect(text.contains("Geely"))
        #expect(text.contains("Monjaro"))
        #expect(text.contains("$9500") || text.contains("$9 500") || text.contains("$9,500"))
        #expect(ChatDraft.normalized(text) == text)
    }
}

struct FilterPersistTests {
    @Test func criteriaAndSortSurviveReload() {
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let seed = SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        let app = AppModel(seed: seed, defaults: defaults, now: { 1 })
        app.criteria.priceFrom = 8_000
        app.criteria.condition = .used
        app.sort = .mileage

        let reloaded = AppModel(seed: seed, defaults: defaults, now: { 1 })
        #expect(reloaded.criteria.priceFrom == 8_000)
        #expect(reloaded.criteria.condition == .used)
        #expect(reloaded.sort == .mileage)
    }

    @Test func conditionTitleIsRussian() {
        #expect(ListingCondition.used.title == "С пробегом")
        #expect(ListingCondition.newCar.title == "Новое")
    }
}

struct EditListingAppModelTests {
    private func signedInModel() -> AppModel {
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let seed = SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        let app = AppModel(seed: seed, defaults: defaults, now: { 1_000_000 })
        app.session = .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        return app
    }

    @Test func saveEditedListingKeepsViewsAndDropsPriceForTracker() throws {
        let app = signedInModel()
        var draft = ListingDraft.sample
        draft.photoURLs = ["file:///tmp/a.jpg"]
        draft.priceBYN = 15_000
        try app.publishDraft(try draft.makeListing(id: "mine-1", seller: app.session.profile!, now: 1_000_000))
        app.markViewed("mine-1")
        app.toggleDeferred("mine-1")

        app.beginEdit("mine-1")
        #expect(app.editingListingID == "mine-1")
        #expect(app.listingDraft.make == "Volkswagen")
        app.listingDraft.priceBYN = 10_000
        app.listingDraft.description = "цена снижена"
        try app.saveEditedListing()

        let saved = try #require(app.listing(id: "mine-1"))
        #expect(saved.priceBYN == 10_000)
        #expect(saved.description == "цена снижена")
        #expect(saved.views == 1)
        #expect(app.editingListingID == nil)
        let dropped = app.deferredPurchase(id: "mine-1")?.usdDropped(currentBYN: saved.priceBYN, usdBYN: app.fx.usdBYN) ?? 0
        #expect(dropped > 0)
    }

    @Test func deferredOfferUsesTargetUSD() throws {
        let listing = listingFixture(id: "lst-1", make: "Geely", model: "Monjaro", price: 30_000)
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let seed = SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        let app = AppModel(seed: seed, defaults: defaults, now: { 1 })
        app.toggleDeferred("lst-1")
        app.setDeferredTargetUSD("lst-1", 9_000)
        let offer = try #require(app.deferredOffer(for: "lst-1"))
        #expect(offer.label.contains("9000") || offer.label.contains("9 000") || offer.label.contains("9,000"))
        #expect(offer.text.contains("Geely"))
        #expect(offer.text.contains("$9000") || offer.text.contains("$9 000") || offer.text.contains("$9,000"))
        #expect(app.deferredOffer(for: "missing") == nil)
    }
}
