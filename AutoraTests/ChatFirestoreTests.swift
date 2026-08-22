import Foundation
import Testing
@testable import Autora

struct FirestoreTimeTests {
    @Test func keepsUnixSeconds() {
        #expect(FirestoreTime.seconds(1_700_000_000) == 1_700_000_000)
    }

    @Test func readsDictionarySeconds() {
        #expect(FirestoreTime.seconds(["seconds": 99.0]) == 99)
    }
}

struct ChatThreadIDTests {
    @Test func isStableRegardlessOfUidOrder() {
        let a = ChatThreadID.make(listingId: "list-1", uidA: "uid-b", uidB: "uid-a")
        let b = ChatThreadID.make(listingId: "list-1", uidA: "uid-a", uidB: "uid-b")
        #expect(a == "chat_list-1_uid-a_uid-b")
        #expect(a == b)
    }
}

struct ChatMessageWireTests {
    @Test func decodesLegacyFromMeWithoutSenderId() throws {
        let data = """
        {"id":"m1","fromMe":true,"text":"привет","at":10}
        """.data(using: .utf8)!
        let message = try JSONDecoder().decode(ChatMessage.self, from: data)
        #expect(message.fromMe)
        #expect(message.senderId.isEmpty)
        #expect(message.oriented(as: "me-local").fromMe)
        #expect(message.oriented(as: "me-local").senderId == "me-local")
    }

    @Test func wireRoundTripUsesSenderId() throws {
        let wire = FirestoreChatMessage(
            id: "m2",
            chatId: "chat_a_me_other",
            senderId: "other",
            text: "завтра",
            at: 50,
            participantIds: ["me", "other"]
        )
        let viewed = wire.asChatMessage(viewerId: "me")
        #expect(viewed.fromMe == false)
        #expect(viewed.senderId == "other")
        #expect(viewed.text == "завтра")
    }
}

struct FirestoreChatThreadWriteTests {
    @Test func emptyLocalThreadDoesNotWipeLastText() {
        let fields = FirestoreChatThread.upsertFields(
            id: "chat_list-1_a_b",
            listingId: "list-1",
            listingTitle: "BMW",
            participantIds: ["a", "b"],
            lastText: "",
            lastAt: 0,
            lastSenderId: "",
            hasMessages: false
        )
        #expect(fields["lastText"] == nil)
        #expect(fields["lastAt"] == nil)
        #expect(fields["listingId"] as? String == "list-1")
    }

    @Test func sentMessageWritesPreview() {
        let fields = FirestoreChatThread.upsertFields(
            id: "chat_list-1_a_b",
            listingId: "list-1",
            listingTitle: "BMW",
            participantIds: ["a", "b"],
            lastText: "привет",
            lastAt: 10,
            lastSenderId: "a",
            hasMessages: true
        )
        #expect(fields["lastText"] as? String == "привет")
        #expect(fields["lastSenderId"] as? String == "a")
    }
}

struct FirestoreListingParseTests {
    @Test func readsSiteListing() {
        let listing = FirestoreListing.parse([
            "id": "user-car-9",
            "sellerId": "uid-real",
            "sellerName": "Борис",
            "sellerPhone": "+37529",
            "make": "BMW",
            "model": "5",
            "year": 2020,
            "priceBYN": 32800,
            "mileageKm": 10,
            "city": "Гродно",
            "title": "BMW 5",
            "photoURLs": ["https://img/x.jpg"],
            "isDemo": false,
        ])
        #expect(listing?.id == "user-car-9")
        #expect(listing?.sellerId == "uid-real")
        #expect(listing?.isDemo == false)
        #expect(listing?.photoURLs == ["https://img/x.jpg"])
    }

    @Test func fallsBackToImageAndResolvesSitePath() {
        let listing = FirestoreListing.parse([
            "id": "list-1",
            "sellerId": "admin-uid",
            "image": "/cars/geely_monjaro.jpg",
            "isDemo": true,
        ])
        #expect(listing?.photoURLs == ["https://coolav.by/cars/geely_monjaro.jpg"])
    }

    @Test func skipsGhostSellersNotDemoFlag() {
        #expect(FirestoreListing.parse(["id": "x", "sellerId": "u", "isDemo": true])?.isDemo == false)
        #expect(FirestoreListing.parse(["id": "x", "sellerId": "demo-seller-list-1"]) == nil)
        #expect(FirestoreListing.parse(["id": "x", "sellerId": ""]) == nil)
    }
}

struct RemoteInboxMergeTests {
    @Test func remoteThreadAppearsAndKeepsLocalMessages() {
        let local = ChatThread(
            id: "chat_list-1_a_b",
            listingId: "list-1",
            listingTitle: "Local",
            peerName: "P",
            unread: 0,
            messages: [ChatMessage(id: "m1", fromMe: true, text: "уже есть", at: 5, senderId: "a")],
            participantIds: ["a", "b"]
        )
        let remote = ChatThread(
            id: "chat_list-1_a_b",
            listingId: "list-1",
            listingTitle: "С сайта",
            peerName: "P",
            unread: 0,
            messages: [],
            participantIds: ["a", "b"],
            lastText: "с сайта",
            lastAt: 20
        )
        let extra = ChatThread(
            id: "chat_list-2_a_c",
            listingId: "list-2",
            listingTitle: "Новый",
            peerName: "C",
            unread: 1,
            messages: [],
            participantIds: ["a", "c"],
            lastText: "hello",
            lastAt: 30
        )
        let merged = RemoteInbox.merge(local: [local], remote: [remote, extra], viewerId: "a")
        #expect(merged.contains { $0.id == "chat_list-2_a_c" })
        let kept = merged.first { $0.id == "chat_list-1_a_b" }
        #expect(kept?.messages.map(\.text) == ["уже есть"])
        #expect(kept?.lastText == "с сайта")
        #expect(kept?.listingTitle == "С сайта")
    }
}
