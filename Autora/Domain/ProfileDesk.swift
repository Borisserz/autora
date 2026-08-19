import Foundation

struct ProfileSnapshot: Equatable, Sendable {
    var isSignedIn: Bool
    var name: String
    var phone: String
    var canPost: Bool
    var listings: Int
    var garage: Int
    var unread: Int
    var compare: Int
    var viewed: Int
    var blocked: Int
    var reports: Int
    var usdBYN: Double
}

enum ProfileDesk {
    static func canPost(phone: String) -> Bool {
        BelarusPhone.e164(phone).count == 13
    }

    static func kicker(_ isSignedIn: Bool) -> String {
        isSignedIn ? "CAB" : "ID"
    }

    static func snapshot(
        session: UserSession,
        listings: Int,
        garage: Int,
        unread: Int,
        compare: Int,
        viewed: Int,
        blocked: Int,
        reports: Int,
        usdBYN: Double
    ) -> ProfileSnapshot {
        let profile = session.profile
        let phone = profile?.phone ?? ""
        return ProfileSnapshot(
            isSignedIn: session.isSignedIn,
            name: profile?.name ?? "",
            phone: phone,
            canPost: session.isSignedIn && canPost(phone: phone),
            listings: listings,
            garage: garage,
            unread: unread,
            compare: compare,
            viewed: viewed,
            blocked: blocked,
            reports: reports,
            usdBYN: usdBYN
        )
    }

    static func headline(_ snap: ProfileSnapshot) -> String {
        if !snap.isSignedIn {
            return "Гость. Войдите, чтобы продавать и писать."
        }
        if !snap.canPost {
            return "Нужен телефон, чтобы подавать объявления."
        }
        var parts = ["\(snap.listings) объявл.", "\(snap.garage) в гараже"]
        if snap.unread > 0 {
            parts.append("\(snap.unread) новых")
        }
        return parts.joined(separator: " · ")
    }

    static func rateLine(_ usdBYN: Double) -> String {
        let value = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), usdBYN)
        return "1 $ = \(value) Br"
    }

    static func reportReason(_ raw: String) -> String {
        switch raw {
        case "spam": "Спам"
        case "sold": "Уже продано"
        case "fraud": "Мошенничество"
        default: raw
        }
    }
}
