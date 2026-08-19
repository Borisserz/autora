import Foundation

enum SellerDeskTab: Int, CaseIterable, Identifiable, Codable, Sendable {
    case all, active, parked, sold

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .all: "Все"
        case .active: "В ленте"
        case .parked: "Снятые"
        case .sold: "Проданные"
        }
    }

    func includes(_ status: ListingStatus) -> Bool {
        switch self {
        case .all: true
        case .active: status == .active || status == .draft
        case .parked: status == .inactive
        case .sold: status == .sold
        }
    }
}

enum SellerDesk {
    static func listings(_ items: [Listing], tab: SellerDeskTab) -> [Listing] {
        items.filter { tab.includes($0.status) }
    }

    static func count(_ tab: SellerDeskTab, in items: [Listing]) -> Int {
        listings(items, tab: tab).count
    }

    static func bumpReady(in items: [Listing], now: TimeInterval) -> [Listing] {
        items.filter {
            $0.status == .active && BumpPolicy.canBump(lastBumped: $0.bumpedAt, now: now)
        }
    }

    static func headline(stats: SellerStats, bumpReady: Int, active: Int) -> String {
        var parts = ["\(active) в ленте", "\(stats.views) просмотров"]
        if bumpReady > 0 {
            parts.insert("\(bumpReady) можно поднять", at: 0)
        }
        return parts.joined(separator: " · ")
    }
}
