import Foundation
import Testing
@testable import Autora

struct PriceConverterTests {
    @Test func usdFromBYNDividesByRate() {
        #expect(PriceConverter.usd(fromBYN: 2990, rate: 2.99) == 1000.0)
    }

    @Test func zeroRateReturnsZero() {
        #expect(PriceConverter.usd(fromBYN: 100, rate: 0) == 0)
    }

    @Test func bynFromUSDRounds() {
        #expect(PriceConverter.byn(fromUSD: 100, rate: 2.99) == 299)
    }

    @Test func filterUSDCeilingRoundTrip() {
        let byn = 15_000
        let usd = PriceConverter.filterUSD(fromBYN: byn, rate: 2.99)
        let back = PriceConverter.byn(fromUSD: Double(usd), rate: 2.99)
        #expect(abs(back - byn) <= 3)
    }

    @Test func formatIncludesCurrency() {
        #expect(PriceConverter.formatBYN(234800).contains("Br"))
        #expect(PriceConverter.formatUSD(12000).hasPrefix("$"))
        #expect(PriceConverter.formatUSDReference(12000).contains("справочно"))
    }
}
