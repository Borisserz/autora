import Foundation

enum ListingTrust {
    static func showsVerifiedSeal(_ listing: Listing) -> Bool {
        listing.isTop
    }

    static func showsSyntheticEquipment(_ listing: Listing) -> Bool {
        !(listing.equipment ?? []).isEmpty
    }

    static func insight(for listing: Listing) -> ModelInsight.Insight? {
        ModelInsight.lookup(make: listing.make, model: listing.model, year: listing.year)
    }
}
