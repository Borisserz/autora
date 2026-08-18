import Foundation

struct SearchCriteria: Equatable, Sendable, Hashable, Codable {
    var query: String = ""
    var make: String?
    var model: String?
    var generation: String?
    var yearFrom: Int?
    var yearTo: Int?
    var priceFrom: Int?
    var priceTo: Int?
    var region: String?
    var city: String?
    var body: String?
    var fuel: String?
    var transmission: String?
    var drivetrain: String?
    var mileageTo: Int?
    var condition: ListingCondition?
    var registered: Bool?
    var customsCleared: Bool?
    var wheel: WheelSide?
    var engineFrom: Double?
    var engineTo: Double?
    var powerFrom: Int?
    var powerTo: Int?
    var hasPhotos: Bool?
    var bargaining: Bool?
    var exchange: Bool?
    var hideSold: Bool = true
    var category: ListingCategoryTab = .all

    var isEmpty: Bool {
        self == SearchCriteria()
    }

    var activeFilterCount: Int {
        var count = 0
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if make != nil { count += 1 }
        if model != nil { count += 1 }
        if generation != nil { count += 1 }
        if yearFrom != nil { count += 1 }
        if yearTo != nil { count += 1 }
        if priceFrom != nil { count += 1 }
        if priceTo != nil { count += 1 }
        if region != nil { count += 1 }
        if city != nil { count += 1 }
        if body != nil { count += 1 }
        if fuel != nil { count += 1 }
        if transmission != nil { count += 1 }
        if drivetrain != nil { count += 1 }
        if mileageTo != nil { count += 1 }
        if condition != nil { count += 1 }
        if registered != nil { count += 1 }
        if customsCleared != nil { count += 1 }
        if wheel != nil { count += 1 }
        if engineFrom != nil { count += 1 }
        if engineTo != nil { count += 1 }
        if powerFrom != nil { count += 1 }
        if powerTo != nil { count += 1 }
        if hasPhotos != nil { count += 1 }
        if bargaining != nil { count += 1 }
        if exchange != nil { count += 1 }
        if hideSold == false { count += 1 }
        if category != .all { count += 1 }
        return count
    }
}

enum ListingFilter {
    static func apply(_ criteria: SearchCriteria, to listings: [Listing], usdBYN: Double = 2.99) -> [Listing] {
        listings.filter { listing in
            if criteria.hideSold, listing.status != .active { return false }
            if listing.forParts == false, listing.status == .active { /* keep */ }
            let q = criteria.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !q.isEmpty {
                let hay = "\(listing.make) \(listing.model) \(listing.generation ?? "") \(listing.city) \(listing.description)".lowercased()
                if !hay.contains(q) { return false }
            }
            if let make = criteria.make, listing.make != make { return false }
            if let model = criteria.model, listing.model != model { return false }
            if let generation = criteria.generation, listing.generation != generation { return false }
            if let yearFrom = criteria.yearFrom, listing.year < yearFrom { return false }
            if let yearTo = criteria.yearTo, listing.year > yearTo { return false }
            if let priceFrom = criteria.priceFrom, listing.priceBYN < priceFrom { return false }
            if let priceTo = criteria.priceTo, listing.priceBYN > priceTo { return false }
            if let region = criteria.region, listing.region != region { return false }
            if let city = criteria.city, listing.city != city { return false }
            if let body = criteria.body, listing.body != body { return false }
            if let fuel = criteria.fuel, listing.fuel != fuel { return false }
            if let transmission = criteria.transmission, listing.transmission != transmission { return false }
            if let drivetrain = criteria.drivetrain, listing.drivetrain != drivetrain { return false }
            if let mileageTo = criteria.mileageTo, listing.mileageKm > mileageTo { return false }
            if let condition = criteria.condition, listing.condition != condition { return false }
            if let registered = criteria.registered, listing.registered != registered { return false }
            if let customsCleared = criteria.customsCleared, listing.customsCleared != customsCleared { return false }
            if let wheel = criteria.wheel, listing.wheel != wheel { return false }
            if let engineFrom = criteria.engineFrom, listing.engineLiters < engineFrom { return false }
            if let engineTo = criteria.engineTo, listing.engineLiters > engineTo { return false }
            if let powerFrom = criteria.powerFrom, listing.powerHp < powerFrom { return false }
            if let powerTo = criteria.powerTo, listing.powerHp > powerTo { return false }
            if let hasPhotos = criteria.hasPhotos, listing.hasPhotos != hasPhotos { return false }
            if let bargaining = criteria.bargaining, listing.bargaining != bargaining { return false }
            if let exchange = criteria.exchange, listing.exchange != exchange { return false }
            if criteria.category != .all, !criteria.category.matches(listing, in: listings, usdBYN: usdBYN) {
                return false
            }
            return true
        }
    }
}

enum ListingSort: String, CaseIterable, Identifiable, Sendable {
    case newest, cheapest, expensive, mileage
    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: "Новые"
        case .cheapest: "Дешёвые"
        case .expensive: "Дорогие"
        case .mileage: "Пробег"
        }
    }

    func apply(_ listings: [Listing]) -> [Listing] {
        switch self {
        case .newest: listings.sorted { $0.bumpedAt > $1.bumpedAt }
        case .cheapest: listings.sorted { $0.priceBYN < $1.priceBYN }
        case .expensive: listings.sorted { $0.priceBYN > $1.priceBYN }
        case .mileage: listings.sorted { $0.mileageKm < $1.mileageKm }
        }
    }
}

enum MarketPrice {
    static let minPeers = 5

    static func peers(for listing: Listing, in all: [Listing]) -> [Listing] {
        all.filter {
            $0.make == listing.make
                && $0.model == listing.model
                && $0.status == .active
                && $0.id != listing.id
                && abs($0.year - listing.year) <= 2
        }
    }

    static func peerAverageBYN(for listing: Listing, in all: [Listing]) -> Int? {
        let peers = peers(for: listing, in: all)
        guard peers.count >= minPeers else { return nil }
        return peers.map(\.priceBYN).reduce(0, +) / peers.count
    }

    static func badge(for listing: Listing, in all: [Listing]) -> String? {
        guard let avg = peerAverageBYN(for: listing, in: all) else { return nil }
        if listing.priceBYN < Int(Double(avg) * 0.92) { return "ниже рынка" }
        if listing.priceBYN > Int(Double(avg) * 1.08) { return "выше рынка" }
        return "около рынка"
    }

    static func caption(_ badge: String) -> String {
        "\(badge) · по выборке CoolAV"
    }
}

struct BrandCount: Identifiable, Hashable, Sendable {
    var id: String { name }
    var name: String
    var count: Int
}

enum BrandCounter {
    static func counts(in listings: [Listing]) -> [BrandCount] {
        grouped(listings, by: \.make)
    }

    static func modelCounts(in listings: [Listing], make: String) -> [BrandCount] {
        grouped(listings.filter { $0.make == make }, by: \.model)
    }

    static func generationCounts(in listings: [Listing], make: String, model: String) -> [BrandCount] {
        let gens = listings
            .filter { $0.status == .active && $0.make == make && $0.model == model }
            .compactMap(\.generation)
            .filter { !$0.isEmpty }
        let grouped = Dictionary(grouping: gens, by: { $0 })
        return grouped.map { BrandCount(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private static func grouped(_ listings: [Listing], by key: KeyPath<Listing, String>) -> [BrandCount] {
        let active = listings.filter { $0.status == .active }
        let grouped = Dictionary(grouping: active, by: { $0[keyPath: key] })
        return grouped.map { BrandCount(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}
