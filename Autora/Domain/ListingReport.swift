import Foundation

struct ListingReport: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var listingID: String
    var reason: String
    var at: TimeInterval
}

enum ChatStartError: Error, Equatable, LocalizedError {
    case needAuth
    case cannotMessageSelf
    case ghostSeller

    var errorDescription: String? {
        switch self {
        case .needAuth: "Войдите, чтобы писать продавцам"
        case .cannotMessageSelf: "Нельзя писать себе"
        case .ghostSeller: "У этой карточки нет живого продавца."
        }
    }

    static func isGhostSeller(_ sellerId: String) -> Bool {
        sellerId.hasPrefix("demo-seller-") || sellerId.hasPrefix("legacy-") || sellerId.hasPrefix("local-")
    }
}

enum AutoraTab: Int, Hashable, CaseIterable {
    case search, favorites, listings, messages, profile
}
