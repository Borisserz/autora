import Foundation

enum PriceDrop {
    static func usdBelowMarket(for listing: Listing, in all: [Listing], usdBYN: Double) -> Int? {
        guard MarketPrice.badge(for: listing, in: all) == "ниже рынка" else { return nil }
        guard let avg = MarketPrice.peerAverageBYN(for: listing, in: all) else { return nil }
        let delta = avg - listing.priceBYN
        guard delta > 0 else { return nil }
        return PriceConverter.filterUSD(fromBYN: delta, rate: usdBYN)
    }
}
