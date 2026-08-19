import Foundation

struct DeferredPurchase: Identifiable, Codable, Equatable, Sendable, Hashable {
    var id: String
    var originalPriceBYN: Int
    var targetPriceUSD: Int
    var userNote: String
    var savedAt: TimeInterval

    static func capturing(_ listing: Listing, now: TimeInterval, usdBYN: Double) -> DeferredPurchase {
        let usd = Int(PriceConverter.usd(fromBYN: listing.priceBYN, rate: usdBYN).rounded())
        return DeferredPurchase(
            id: listing.id,
            originalPriceBYN: listing.priceBYN,
            targetPriceUSD: Int((Double(usd) * 0.95).rounded()),
            userNote: "",
            savedAt: now
        )
    }

    func usdDropped(currentBYN: Int, usdBYN: Double) -> Int {
        let delta = originalPriceBYN - currentBYN
        guard delta > 0 else { return 0 }
        return PriceConverter.filterUSD(fromBYN: delta, rate: usdBYN)
    }

    func isTargetReached(currentBYN: Int, usdBYN: Double) -> Bool {
        Int(PriceConverter.usd(fromBYN: currentBYN, rate: usdBYN).rounded()) <= targetPriceUSD
    }

    func usdToTarget(currentBYN: Int, usdBYN: Double) -> Int {
        let current = Int(PriceConverter.usd(fromBYN: currentBYN, rate: usdBYN).rounded())
        return max(0, current - targetPriceUSD)
    }
}
