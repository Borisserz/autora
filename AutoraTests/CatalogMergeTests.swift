import Foundation
import Testing
@testable import Autora

struct CatalogMergeTests {
    @Test func listingsKeepMineFirstAndReplaceSeedByID() {
        let seed = listingFixture(id: "a", price: 1)
        let mine = listingFixture(id: "mine", price: 2)
        let mineOverride = listingFixture(id: "a", price: 99)
        let merged = CatalogMerge.listings(seed: [seed], mine: [mine, mineOverride])
        #expect(merged.map(\.id) == ["mine", "a"])
        #expect(merged.first { $0.id == "a" }?.priceBYN == 99)
    }

    @Test func remoteListingsSitBetweenMineAndSeedIncludingDemo() {
        let seed = listingFixture(id: "seed-1", price: 1)
        let mine = listingFixture(id: "mine", price: 2, isDemo: false)
        let remoteLive = listingFixture(id: "user-car-9", sellerId: "uid-real", price: 3, isDemo: false)
        let remoteDemo = listingFixture(id: "list-1", sellerId: "admin-uid", price: 4, isDemo: true)
        let merged = CatalogMerge.listings(seed: [seed], mine: [mine], remote: [remoteLive, remoteDemo])
        #expect(merged.map(\.id) == ["mine", "user-car-9", "list-1", "seed-1"])
    }

    @Test func chatsLiveWinsAndKeepsExtras() {
        let seed = ChatThread(id: "chat-001", listingId: "s", listingTitle: "S", peerName: "P", unread: 2, messages: [])
        let liveSeed = ChatThread(id: "chat-001", listingId: "s", listingTitle: "S", peerName: "P", unread: 0, messages: [])
        let extra = ChatThread(id: "chat-mine", listingId: "m", listingTitle: "M", peerName: "Q", unread: 0, messages: [])
        let merged = CatalogMerge.chats(seed: [seed], live: [liveSeed, extra])
        #expect(merged.contains { $0.id == "chat-mine" })
        #expect(merged.first { $0.id == "chat-001" }?.unread == 0)
    }
}
