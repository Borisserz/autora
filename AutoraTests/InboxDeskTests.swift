import Foundation
import Testing
@testable import Autora

struct InboxDeskTests {
    @Test func sortsByLastMessageAndFiltersUnreadAndOffers() {
        let old = ChatThread(
            id: "old",
            listingId: "a",
            listingTitle: "A",
            peerName: "Анна",
            unread: 0,
            messages: [ChatMessage(id: "1", fromMe: true, text: "привет", at: 10)]
        )
        let freshUnread = ChatThread(
            id: "fresh",
            listingId: "b",
            listingTitle: "B",
            peerName: "Борис",
            unread: 2,
            messages: [ChatMessage(id: "2", fromMe: false, text: "завтра", at: 50)]
        )
        let offer = ChatThread(
            id: "offer",
            listingId: "c",
            listingTitle: "C",
            peerName: "Кира",
            unread: 0,
            messages: []
        )
        let all = [old, freshUnread, offer]
        #expect(InboxDesk.sorted(all).map(\.id) == ["fresh", "old", "offer"])
        #expect(InboxDesk.listings(all, tab: .unread, deferredIDs: []).map(\.id) == ["fresh"])
        #expect(InboxDesk.listings(all, tab: .offers, deferredIDs: ["c"]).map(\.id) == ["offer"])
        #expect(InboxDesk.preview(old) == "Вы: привет")
        #expect(InboxDesk.preview(freshUnread) == "завтра")
        let fromSite = ChatThread(
            id: "site",
            listingId: "d",
            listingTitle: "D",
            peerName: "Сайт",
            unread: 0,
            messages: [],
            lastText: "с CoolAV"
        )
        #expect(InboxDesk.preview(fromSite) == "с CoolAV")
        #expect(InboxDesk.headline(unread: 3, threads: 5) == "3 непрочитанных · 5 переписок")
        #expect(InboxDesk.headline(unread: 0, threads: 2) == "2 переписки")
        #expect(InboxTab.allCases.map(\.title) == ["Все", "Новые", "К цели"])
        let seed = ChatThread(id: "chat-001", listingId: "a", listingTitle: "A", peerName: "P", unread: 1, messages: [])
        #expect(InboxDesk.chats(seed: [seed], stored: [], deleted: [], isSignedIn: false).isEmpty)
        #expect(InboxDesk.chats(seed: [seed], stored: [], deleted: [], isSignedIn: true).map(\.id) == ["chat-001"])
        #expect(InboxDesk.chats(seed: [seed], stored: [], deleted: ["chat-001"], isSignedIn: true).isEmpty)
        let live = ChatThread(id: "mine", listingId: "b", listingTitle: "B", peerName: "Q", unread: 0, messages: [])
        #expect(InboxDesk.chats(seed: [seed], stored: [live], deleted: [], isSignedIn: false).map(\.id) == ["mine"])
    }

    @Test func inboxTabAndDeleteThreadPersist() throws {
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
        app.inboxTab = .unread
        app.deleteThread(id)
        #expect(app.chats.isEmpty)

        let seedThread = ChatThread(
            id: "chat-001",
            listingId: "a",
            listingTitle: "A",
            peerName: "P",
            unread: 1,
            messages: []
        )
        let withSeed = AppModel(
            seed: SeedFile(listings: [listing], chats: [seedThread], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!,
            now: { 1 }
        )
        withSeed.signInDemo()
        withSeed.deleteThread("chat-001")
        let reloadedSeed = AppModel(
            seed: SeedFile(listings: [listing], chats: [seedThread], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: withSeed.defaults,
            now: { 1 }
        )
        #expect(!reloadedSeed.chats.contains { $0.id == "chat-001" })

        let reloaded = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        #expect(reloaded.inboxTab == .unread)
    }

    @Test func markAllReadClearsBadge() {
        let thread = ChatThread(
            id: "chat-001",
            listingId: "a",
            listingTitle: "S",
            peerName: "P",
            unread: 2,
            messages: []
        )
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let app = AppModel(
            seed: SeedFile(listings: [], chats: [thread], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        app.chats = [thread]
        #expect(app.unreadCount == 2)
        app.markAllRead()
        #expect(app.unreadCount == 0)
    }

    @Test func guestDoesNotLoadSeedChatsUntilSignIn() {
        let seed = ChatThread(id: "chat-001", listingId: "a", listingTitle: "A", peerName: "P", unread: 1, messages: [])
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let guest = AppModel(
            seed: SeedFile(listings: [], chats: [seed], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        #expect(guest.chats.isEmpty)
        guest.signInDemo()
        #expect(guest.chats.map(\.id) == ["chat-001"])
    }

    @Test func quickRepliesAreShortRussian() {
        #expect(ChatDraft.quickReplies.count == 3)
        #expect(ChatDraft.quickReplies.allSatisfy { !$0.isEmpty && ChatDraft.normalized($0) != nil })
    }
}
