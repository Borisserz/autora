import Foundation

enum ListingStatus: String, Codable, Equatable, Sendable {
    case active, sold, draft, inactive
}

enum ListingCondition: String, Codable, Equatable, Sendable, CaseIterable {
    case used
    case newCar = "new"

    var title: String {
        switch self {
        case .used: "С пробегом"
        case .newCar: "Новое"
        }
    }
}

enum WheelSide: String, Codable, Equatable, Sendable {
    case left, right
}

struct Listing: Identifiable, Codable, Equatable, Sendable, Hashable {
    var id: String
    var sellerId: String
    var sellerName: String
    var sellerPhone: String
    var sellerListingCount: Int
    var make: String
    var model: String
    var generation: String?
    var year: Int
    var priceBYN: Int
    var mileageKm: Int
    var body: String
    var fuel: String
    var transmission: String
    var drivetrain: String
    var engineLiters: Double
    var powerHp: Int
    var city: String
    var region: String
    var condition: ListingCondition
    var registered: Bool
    var customsCleared: Bool
    var wheel: WheelSide
    var hasPhotos: Bool
    var bargaining: Bool
    var exchange: Bool
    var forParts: Bool
    var damaged: Bool
    var vin: String?
    var isTop: Bool
    var isDemo: Bool
    var status: ListingStatus
    var photoURLs: [String]
    var description: String
    var views: Int
    var favoritesCount: Int
    var phoneReveals: Int
    var bumpedAt: TimeInterval
    var createdAt: TimeInterval
    var equipment: [String]? = nil

    var title: String { "\(make) \(model)" }

    var specLine: String {
        var parts = ["\(year)"]
        if let generation, !generation.isEmpty { parts.append(generation) }
        parts.append("\(mileageKm.formatted()) км")
        parts.append(transmission)
        return parts.joined(separator: " · ")
    }

    var hasVIN: Bool {
        guard let vin else { return false }
        return !vin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
