import Foundation

struct SellerStats: Equatable, Sendable {
    var listingCount: Int
    var views: Int
    var favorites: Int
    var phoneReveals: Int

    static func from(_ listings: [Listing]) -> SellerStats {
        SellerStats(
            listingCount: listings.count,
            views: listings.reduce(0) { $0 + $1.views },
            favorites: listings.reduce(0) { $0 + $1.favoritesCount },
            phoneReveals: listings.reduce(0) { $0 + $1.phoneReveals }
        )
    }
}
