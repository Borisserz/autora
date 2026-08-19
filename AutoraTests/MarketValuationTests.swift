import Foundation
import Testing
@testable import Autora

struct MarketValuationTests {
    @Test func geelyGoodConditionMatchesSiteFormula() {
        let quote = MarketValuation.quote(
            make: "Geely",
            year: 2022,
            mileageKm: 45_000,
            condition: .good,
            usdBYN: 2.99,
            nowYear: 2026
        )
        #expect(quote.usd == 21_853)
        #expect(quote.byn == 65_340)
        #expect(quote.minUSD == 20_323)
        #expect(quote.maxUSD == 23_383)
        #expect(quote.days == 30)
    }

    @Test func excellentConditionRaisesPriceAndCutsDays() {
        let good = MarketValuation.quote(
            make: "BMW",
            year: 2020,
            mileageKm: 80_000,
            condition: .good,
            usdBYN: 2.99,
            nowYear: 2026
        )
        let excellent = MarketValuation.quote(
            make: "BMW",
            year: 2020,
            mileageKm: 80_000,
            condition: .excellent,
            usdBYN: 2.99,
            nowYear: 2026
        )
        #expect(excellent.usd > good.usd)
        #expect(excellent.days < good.days)
    }
}

struct MarketLiquidityTitleTests {
    @Test func daysMapToHonestRussianBands() {
        #expect(MarketValuation.liquidityTitle(days: 12) == "высокая")
        #expect(MarketValuation.liquidityTitle(days: 18) == "средняя")
        #expect(MarketValuation.liquidityTitle(days: 30) == "ниже средней")
    }
}

struct LeaseQuoteTests {
    @Test func monthlyPaymentMatchesSiteInterestRule() {
        let monthly = LeaseQuote.monthlyBYN(
            priceUSD: 10_000,
            downPercent: 30,
            years: 3,
            usdBYN: 3.28
        )
        #expect(monthly == 867)
    }
}

struct PriceDisplayTests {
    @Test func catalogShowsUSDPrimaryAndApproxBYN() {
        #expect(PriceConverter.formatUSD(34_500) == "$34,500" || PriceConverter.formatUSD(34_500).hasPrefix("$"))
        #expect(PriceConverter.formatApproxBYN(113_160).hasPrefix("≈"))
        #expect(PriceConverter.formatApproxBYN(113_160).contains("Br"))
    }

    @Test func pairFlipsWhenShowUSDIsOff() {
        let usdOn = PriceDisplay.pair(byn: 2_990, rate: 2.99, showUSD: true)
        #expect(usdOn.primary.hasPrefix("$"))
        #expect(usdOn.secondary.contains("Br"))
        let bynOn = PriceDisplay.pair(byn: 2_990, rate: 2.99, showUSD: false)
        #expect(bynOn.primary.contains("Br"))
        #expect(bynOn.secondary.contains("$"))
    }
}
