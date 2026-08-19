import Foundation
import Testing
@testable import Autora

struct SellerDeskTests {
    @Test func filtersByStatusAndCountsPills() {
        let active = listingFixture(id: "a", status: .active)
        let sold = listingFixture(id: "s", status: .sold)
        let parked = listingFixture(id: "p", status: .inactive)
        let all = [active, sold, parked]
        #expect(SellerDesk.listings(all, tab: .all).map(\.id) == ["a", "s", "p"])
        #expect(SellerDesk.listings(all, tab: .active).map(\.id) == ["a"])
        #expect(SellerDesk.listings(all, tab: .parked).map(\.id) == ["p"])
        #expect(SellerDesk.listings(all, tab: .sold).map(\.id) == ["s"])
        #expect(SellerDesk.count(.sold, in: all) == 1)
        #expect(SellerDeskTab.allCases.map(\.title) == ["Все", "В ленте", "Снятые", "Проданные"])
        #expect(ListingStatus.active.title == "В ленте")
        #expect(ListingStatus.inactive.title == "Снято")
    }

    @Test func headlinePutsBumpReadyFirst() {
        let stats = SellerStats(listingCount: 3, views: 40, favorites: 2, phoneReveals: 1)
        #expect(SellerDesk.headline(stats: stats, bumpReady: 2, active: 1) == "2 можно поднять · 1 в ленте · 40 просмотров")
        #expect(SellerDesk.headline(stats: stats, bumpReady: 0, active: 0) == "0 в ленте · 40 просмотров")
    }

    @Test func bumpReadyOnlyActivePastInterval() {
        let ready = listingFixture(id: "r", status: .active, bumpedAt: 1)
        let fresh = listingFixture(id: "f", status: .active, bumpedAt: 100_000)
        let sold = listingFixture(id: "s", status: .sold, bumpedAt: 1)
        let now: TimeInterval = 1 + BumpPolicy.interval
        #expect(SellerDesk.bumpReady(in: [ready, fresh, sold], now: now).map(\.id) == ["r"])
    }

    @Test func deskTabAndDuplicateDraftPersist() throws {
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
        app.sellerDeskTab = .parked
        app.duplicateAsDraft("mine-1")
        #expect(app.listingDraft.make == "Volkswagen")
        #expect(app.editingListingID == nil)
        #expect(app.pendingOpenWizard)

        let reloaded = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1_000_000 }
        )
        #expect(reloaded.sellerDeskTab == .parked)
    }
}
