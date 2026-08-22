import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum RemoteChatError: Error, LocalizedError, Equatable {
    case notConfigured
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Добавь Firebase Auth + Firestore в Xcode и GoogleService-Info.plist — тогда чат совпадёт с сайтом."
        case .failed(let message):
            return message
        }
    }
}

enum RemoteChatStore {
    static var isLive: Bool {
        #if canImport(FirebaseCore)
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        #else
        false
        #endif
    }

    static var isConfigured: Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.app() != nil
        #else
        false
        #endif
    }

    static var canUseAuth: Bool {
        FirebaseBootstrap.mayAccessAuth(plistPresent: isLive, appConfigured: isConfigured)
    }

    static func signOutRemote() {
        #if canImport(FirebaseAuth)
        configure()
        guard canUseAuth else { return }
        try? Auth.auth().signOut()
        #endif
    }

    static func currentProfile() -> UserProfile? {
        #if canImport(FirebaseAuth)
        configure()
        guard canUseAuth, let user = Auth.auth().currentUser else { return nil }
        return UserProfile(
            id: user.uid,
            name: user.displayName ?? user.email ?? "Пользователь",
            phone: user.phoneNumber ?? "",
            isOwner: false
        )
        #else
        return nil
        #endif
    }

    static func listenListings(_ onNext: @escaping @Sendable ([Listing]) -> Void) {
        #if canImport(FirebaseFirestore)
        configure()
        guard canUseAuth else { return }
        Firestore.firestore().collection("autora_listings").addSnapshotListener { snap, _ in
            onNext(snap?.documents.compactMap { FirestoreListing.parse($0.data()) } ?? [])
        }
        #endif
    }

    static func listenInbox(uid: String, _ onNext: @escaping @Sendable ([ChatThread]) -> Void) {
        #if canImport(FirebaseFirestore)
        configure()
        guard canUseAuth else { return }
        Firestore.firestore().collection("autora_chats")
            .whereField("participantIds", arrayContains: uid)
            .addSnapshotListener { snap, _ in
                onNext(snap?.documents.map { FirestoreChatThread.parse($0.documentID, $0.data(), viewerId: uid) } ?? [])
            }
        #endif
    }

    static func configure() {
        #if canImport(FirebaseCore)
        guard isLive else { return }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }

    static func signIn(email: String, password: String) async throws -> UserProfile {
        #if canImport(FirebaseAuth)
        configure()
        guard canUseAuth else { throw RemoteChatError.notConfigured }
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = result.user
        let profile = UserProfile(
            id: user.uid,
            name: user.displayName ?? email,
            phone: user.phoneNumber ?? "",
            isOwner: false
        )
        await upsertUser(profile, email: user.email)
        return profile
        #else
        throw RemoteChatError.notConfigured
        #endif
    }

    static func register(email: String, password: String, name: String) async throws -> UserProfile {
        #if canImport(FirebaseAuth)
        configure()
        guard canUseAuth else { throw RemoteChatError.notConfigured }
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let change = result.user.createProfileChangeRequest()
        change.displayName = name
        try await change.commitChanges()
        let profile = UserProfile(id: result.user.uid, name: name, phone: "", isOwner: false)
        await upsertUser(profile, email: result.user.email)
        return profile
        #else
        throw RemoteChatError.notConfigured
        #endif
    }

    static func upsertUser(_ profile: UserProfile, email: String?) async {
        #if canImport(FirebaseFirestore)
        guard isLive else { return }
        let db = Firestore.firestore()
        try? await db.collection("autora_users").document(profile.id).setData([
            "id": profile.id,
            "name": profile.name,
            "phone": profile.phone,
            "email": email ?? "",
        ], merge: true)
        #endif
    }

    static func pushListing(_ listing: Listing) async {
        #if canImport(FirebaseFirestore)
        guard isLive else { return }
        let db = Firestore.firestore()
        try? await db.collection("autora_listings").document(listing.id).setData([
            "id": listing.id,
            "sellerId": listing.sellerId,
            "sellerName": listing.sellerName,
            "sellerPhone": listing.sellerPhone,
            "make": listing.make,
            "model": listing.model,
            "year": listing.year,
            "priceBYN": listing.priceBYN,
            "mileageKm": listing.mileageKm,
            "city": listing.city,
            "body": listing.body,
            "bodyType": listing.body,
            "fuel": listing.fuel,
            "fuelType": listing.fuel,
            "transmission": listing.transmission,
            "drivetrain": listing.drivetrain,
            "drive": listing.drivetrain,
            "status": listing.status.rawValue,
            "isDemo": false,
            "title": listing.title,
            "description": listing.description,
            "photoURLs": listing.photoURLs,
            "image": listing.photoURLs.first ?? "",
            "createdAt": listing.createdAt,
            "bumpedAt": listing.bumpedAt,
            "verified": false,
            "historyCheck": false,
        ], merge: true)
        #endif
    }

    static func fetchListings() async -> [Listing] {
        #if canImport(FirebaseFirestore)
        guard isLive else { return [] }
        let db = Firestore.firestore()
        guard let snap = try? await db.collection("autora_listings").getDocuments() else { return [] }
        return snap.documents.compactMap { FirestoreListing.parse($0.data()) }
        #else
        return []
        #endif
    }

    static func fetchInbox(uid: String) async -> [ChatThread] {
        #if canImport(FirebaseFirestore)
        guard isLive else { return [] }
        let db = Firestore.firestore()
        guard let snap = try? await db.collection("autora_chats")
            .whereField("participantIds", arrayContains: uid)
            .getDocuments() else { return [] }
        return snap.documents.map { FirestoreChatThread.parse($0.documentID, $0.data(), viewerId: uid) }
        #else
        return []
        #endif
    }

    static func fetchMessages(threadId: String, uid: String) async -> [ChatMessage] {
        #if canImport(FirebaseFirestore)
        guard isLive else { return [] }
        let db = Firestore.firestore()
        guard let snap = try? await db.collection("autora_messages")
            .whereField("participantIds", arrayContains: uid)
            .getDocuments() else { return [] }
        return snap.documents
            .compactMap { doc -> ChatMessage? in
                let data = doc.data()
                let chatId = data["chatId"] as? String ?? ""
                guard chatId == threadId else { return nil }
                return FirestoreChatMessage(
                    id: doc.documentID,
                    chatId: chatId,
                    senderId: data["senderId"] as? String ?? "",
                    text: data["text"] as? String ?? "",
                    at: FirestoreTime.seconds(data["at"]),
                    participantIds: data["participantIds"] as? [String] ?? []
                ).asChatMessage(viewerId: uid)
            }
            .sorted { $0.at < $1.at }
        #else
        return []
        #endif
    }

    static func pushThread(_ thread: ChatThread) async {
        #if canImport(FirebaseFirestore)
        guard isLive else { return }
        let db = Firestore.firestore()
        let last = thread.messages.last
        try? await db.collection("autora_chats").document(thread.id).setData(
            FirestoreChatThread.upsertFields(
                id: thread.id,
                listingId: thread.listingId,
                listingTitle: thread.listingTitle,
                participantIds: thread.participantIds,
                lastText: last?.text ?? thread.lastText,
                lastAt: last?.at ?? thread.lastAt,
                lastSenderId: last?.senderId ?? "",
                hasMessages: last != nil || !thread.lastText.isEmpty
            ),
            merge: true
        )
        #endif
    }

    static func pushMessage(thread: ChatThread, message: ChatMessage) async {
        #if canImport(FirebaseFirestore)
        guard isLive else { return }
        let db = Firestore.firestore()
        try? await db.collection("autora_messages").document(message.id).setData([
            "id": message.id,
            "chatId": thread.id,
            "senderId": message.senderId,
            "text": message.text,
            "at": message.at,
            "participantIds": thread.participantIds,
        ])
        try? await db.collection("autora_chats").document(thread.id).setData([
            "lastText": message.text,
            "lastAt": message.at,
            "lastSenderId": message.senderId,
            "participantIds": thread.participantIds,
            "listingId": thread.listingId,
            "listingTitle": thread.listingTitle,
        ], merge: true)
        #endif
    }
}
