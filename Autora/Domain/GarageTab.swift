import Foundation

enum GarageTab: Int, CaseIterable, Identifiable, Codable, Sendable {
    case favorites, deferred, fleet, searches

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .favorites: "Избранное"
        case .deferred: "Отложенные"
        case .fleet: "Автопарк"
        case .searches: "Поиски"
        }
    }

    var symbol: String {
        switch self {
        case .favorites: "heart.fill"
        case .deferred: "bell.fill"
        case .fleet: "car.fill"
        case .searches: "magnifyingglass"
        }
    }
}

enum GarageOverview {
    static func count(
        _ tab: GarageTab,
        favoriteIDs: Set<String>,
        listings: [Listing],
        deferred: [DeferredPurchase],
        fleet: Int,
        searches: Int
    ) -> Int {
        let ids = Set(listings.map(\.id))
        switch tab {
        case .favorites: return favoriteIDs.filter { ids.contains($0) }.count
        case .deferred: return deferred.filter { ids.contains($0.id) }.count
        case .fleet: return fleet
        case .searches: return searches
        }
    }

    static func headline(drops: Int, favorites: Int, fleet: Int) -> String {
        var parts: [String] = []
        if drops > 0 { parts.append("\(drops) к цели") }
        if favorites > 0 { parts.append("\(favorites) в избранном") }
        if fleet > 0 { parts.append("\(fleet) своих") }
        return parts.isEmpty ? "Пусто. Сердце на карточке — и авто здесь." : parts.joined(separator: " · ")
    }

    static func carTotal(favorites: Int, deferred: Int, fleet: Int) -> Int {
        favorites + deferred + fleet
    }
}
