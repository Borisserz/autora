import Foundation
import Testing
@testable import Autora

struct ChatReplyTests {
    @Test func sellerReplyIsStableDemoCopy() {
        #expect(ChatDraft.sellerReply.contains("18"))
        #expect(ChatDraft.sellerReply.contains("Торг"))
    }

    @Test func sendMessageAppendsSellerReply() throws {
        let listing = listingFixture(id: "a", sellerId: "other")
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let app = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        app.session = .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        let id = try app.startChat(for: listing)
        app.sendMessage(threadID: id, text: "тест")
        let messages = app.chats.first { $0.id == id }?.messages ?? []
        #expect(messages.count == 2)
        #expect(messages[0].fromMe && messages[0].text == "тест")
        #expect(!messages[1].fromMe)
        #expect(messages[1].text == ChatDraft.sellerReply)
    }
}

struct DeleteListingTests {
    @Test func deleteOwnListingRemovesAndPersists() throws {
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let app = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1_000_000 }
        )
        app.session = .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+37529", isOwner: false))
        var draft = ListingDraft.sample
        draft.photoURLs = ["file:///tmp/a.jpg"]
        try app.publishDraft(try draft.makeListing(id: "mine-1", seller: app.session.profile!, now: 1_000_000))
        app.toggleFavorite("mine-1")
        app.toggleDeferred("mine-1")
        app.deleteListing("mine-1")
        #expect(app.listing(id: "mine-1") == nil)
        #expect(app.myListings.isEmpty)
        #expect(!app.favoriteIDs.contains("mine-1"))
        #expect(!app.isDeferred("mine-1"))

        let reloaded = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1_000_000 }
        )
        #expect(reloaded.listing(id: "mine-1") == nil)
    }

    @Test func deleteIgnoresForeignListing() {
        let listing = listingFixture(id: "seed-1", sellerId: "other")
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let app = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        app.deleteListing("seed-1")
        #expect(app.listing(id: "seed-1") != nil)
    }
}

struct UnblockSellerTests {
    @Test func unblockRestoresListingInFeed() {
        let listing = listingFixture(id: "a", sellerId: "bad", make: "Audi")
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let app = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        app.block(sellerID: "bad")
        #expect(app.filtered.isEmpty)
        #expect(app.blockedSellers.map(\.id) == ["bad"])
        app.unblock(sellerID: "bad")
        #expect(app.filtered.map(\.id) == ["a"])
        #expect(app.blockedSellers.isEmpty)

        let reloaded = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        #expect(!reloaded.blockedSellerIDs.contains("bad"))
        #expect(reloaded.filtered.map(\.id) == ["a"])
    }
}

struct DeferredWatchTests {
    @Test func dropCaptionWhenPriceFell() {
        let item = DeferredPurchase(
            id: "d1",
            originalPriceBYN: 3_000,
            targetPriceUSD: 900,
            userNote: "",
            savedAt: 1
        )
        #expect(DeferredWatch.caption(purchase: item, currentBYN: 2_400, usdBYN: 3.0) == "цель $900")
        #expect(DeferredWatch.caption(purchase: item, currentBYN: 3_500, usdBYN: 3.0) == nil)
        #expect(DeferredWatch.caption(purchase: item, currentBYN: 2_850, usdBYN: 3.0) == "−$50 от старта")
    }

    @Test func droppedListingsFollowsDeferredWatch() {
        let listing = listingFixture(id: "d1", price: 2_400)
        let purchases = [
            DeferredPurchase(id: "d1", originalPriceBYN: 3_000, targetPriceUSD: 900, userNote: "", savedAt: 1)
        ]
        #expect(DeferredWatch.dropped(in: [listing], purchases: purchases, usdBYN: 3.0).map(\.id) == ["d1"])
        #expect(DeferredWatch.dropped(in: [listingFixture(id: "d1", price: 3_500)], purchases: purchases, usdBYN: 3.0).isEmpty)
    }
}
