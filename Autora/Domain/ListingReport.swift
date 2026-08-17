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

    var errorDescription: String? {
        switch self {
        case .needAuth: "Войдите, чтобы писать продавцам"
        case .cannotMessageSelf: "Нельзя писать себе"
        }
    }
}

enum AutoraTab: Int, Hashable, CaseIterable {
    case search, favorites, listings, messages, profile
}
