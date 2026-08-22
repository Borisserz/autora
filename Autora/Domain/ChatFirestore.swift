import Foundation

enum ChatThreadID {
    static func make(listingId: String, uidA: String, uidB: String) -> String {
        let pair = [uidA, uidB].sorted()
        return "chat_\(listingId)_\(pair[0])_\(pair[1])"
    }
}

enum FirestoreTime {
    static func seconds(_ value: Any?) -> TimeInterval {
        if let number = value as? TimeInterval { return number > 1e12 ? number / 1000 : number }
        if let number = value as? Int { return TimeInterval(number) }
        if let dict = value as? [String: Any] {
            if let seconds = dict["seconds"] as? TimeInterval { return seconds }
            if let seconds = dict["_seconds"] as? TimeInterval { return seconds }
        }
        return 0
    }
}

struct FirestoreChatMessage: Codable, Equatable, Sendable {
    var id: String
    var chatId: String
    var senderId: String
    var text: String
    var at: TimeInterval
    var participantIds: [String]

    func asChatMessage(viewerId: String) -> ChatMessage {
        ChatMessage(
            id: id,
            fromMe: senderId == viewerId,
            text: text,
            at: at,
            senderId: senderId
        )
    }
}

enum FirestoreChatThread {
    static func upsertFields(
        id: String,
        listingId: String,
        listingTitle: String,
        participantIds: [String],
        lastText: String,
        lastAt: TimeInterval,
        lastSenderId: String,
        hasMessages: Bool
    ) -> [String: Any] {
        var fields: [String: Any] = [
            "id": id,
            "listingId": listingId,
            "listingTitle": listingTitle,
            "participantIds": participantIds,
        ]
        if hasMessages {
            fields["lastText"] = lastText
            fields["lastAt"] = lastAt
            fields["lastSenderId"] = lastSenderId
        }
        return fields
    }

    static func parse(_ id: String, _ data: [String: Any], viewerId: String) -> ChatThread {
        let participants = (data["participantIds"] as? [String]) ?? []
        let peer = participants.first { $0 != viewerId } ?? ""
        return ChatThread(
            id: id,
            listingId: data["listingId"] as? String ?? "",
            listingTitle: data["listingTitle"] as? String ?? "",
            peerName: data["peerName"] as? String ?? peer,
            unread: 0,
            messages: [],
            participantIds: participants,
            lastText: data["lastText"] as? String ?? "",
            lastAt: FirestoreTime.seconds(data["lastAt"])
        )
    }
}

enum FirestoreListing {
    static func intValue(_ value: Any?, fallback: Int = 0) -> Int {
        if let number = value as? Int { return number }
        if let number = value as? Double { return Int(number) }
        return fallback
    }

    static func parse(_ data: [String: Any]) -> Listing? {
        let id = data["id"] as? String ?? ""
        let sellerId = data["sellerId"] as? String ?? ""
        if id.isEmpty || sellerId.isEmpty { return nil }
        if sellerId.hasPrefix("demo-seller-") || sellerId.hasPrefix("legacy-") || sellerId.hasPrefix("local-") { return nil }
        if let status = data["status"] as? String, status == "inactive" || status == "sold" { return nil }
        var photos = (data["photoURLs"] as? [Any])?.compactMap { $0 as? String } ?? []
        if photos.isEmpty, let image = data["image"] as? String, !image.isEmpty {
            photos = [image]
        }
        photos = photos.map { ListingPhotoURL.normalized($0) }
        let make = data["make"] as? String ?? ""
        let model = data["model"] as? String ?? ""
        return Listing(
            id: id,
            sellerId: sellerId,
            sellerName: data["sellerName"] as? String ?? "Продавец",
            sellerPhone: data["sellerPhone"] as? String ?? "",
            sellerListingCount: 1,
            make: make,
            model: model,
            generation: nil,
            year: intValue(data["year"], fallback: 2020),
            priceBYN: intValue(data["priceBYN"]),
            mileageKm: intValue(data["mileageKm"]),
            body: data["bodyType"] as? String ?? data["body"] as? String ?? "седан",
            fuel: data["fuelType"] as? String ?? data["fuel"] as? String ?? "бензин",
            transmission: data["transmission"] as? String ?? "автомат",
            drivetrain: data["drive"] as? String ?? data["drivetrain"] as? String ?? "передний",
            engineLiters: data["engineLiters"] as? Double ?? 0,
            powerHp: data["powerHp"] as? Int ?? 0,
            city: data["city"] as? String ?? "Беларусь",
            region: data["region"] as? String ?? "",
            condition: .used,
            registered: true,
            customsCleared: true,
            wheel: .left,
            hasPhotos: !photos.isEmpty,
            bargaining: false,
            exchange: false,
            forParts: false,
            damaged: false,
            vin: nil,
            isTop: false,
            isDemo: data["isDemo"] as? Bool ?? false,
            status: .active,
            photoURLs: photos,
            description: data["title"] as? String ?? "\(make) \(model)",
            views: 0,
            favoritesCount: 0,
            phoneReveals: 0,
            bumpedAt: FirestoreTime.seconds(data["createdAt"]),
            createdAt: FirestoreTime.seconds(data["createdAt"])
        )
    }
}

enum RemoteInbox {
    static func merge(local: [ChatThread], remote: [ChatThread], viewerId: String) -> [ChatThread] {
        var byID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for thread in remote {
            if var existing = byID[thread.id] {
                if !thread.listingTitle.isEmpty { existing.listingTitle = thread.listingTitle }
                if !thread.participantIds.isEmpty { existing.participantIds = thread.participantIds }
                if !thread.lastText.isEmpty { existing.lastText = thread.lastText }
                if thread.lastAt > existing.lastAt { existing.lastAt = thread.lastAt }
                if thread.messages.count >= existing.messages.count, !thread.messages.isEmpty {
                    existing.messages = thread.messages.map { $0.oriented(as: viewerId) }
                }
                byID[thread.id] = existing
            } else {
                var copy = thread
                copy.messages = thread.messages.map { $0.oriented(as: viewerId) }
                byID[thread.id] = copy
            }
        }
        return Array(byID.values)
    }
}
