import Foundation
import Testing
@testable import Autora

struct DeferredPurchaseTests {
    @Test func capturingSetsOriginalAndDefaultTarget() {
        let listing = listingFixture(id: "d1", price: 2_990)
        let item = DeferredPurchase.capturing(listing, now: 1_000, usdBYN: 2.99)
        #expect(item.id == "d1")
        #expect(item.originalPriceBYN == 2_990)
        #expect(item.targetPriceUSD == 950)
        #expect(item.userNote.isEmpty)
        #expect(item.savedAt == 1_000)
    }

    @Test func usdDroppedFromOriginalPrice() {
        let item = DeferredPurchase(
            id: "d1",
            originalPriceBYN: 3_000,
            targetPriceUSD: 900,
            userNote: "",
            savedAt: 1
        )
        #expect(item.usdDropped(currentBYN: 2_400, usdBYN: 3.0) == 200)
        #expect(item.usdDropped(currentBYN: 3_500, usdBYN: 3.0) == 0)
    }

    @Test func targetReachedWhenCurrentUSDAtOrBelowTarget() {
        let item = DeferredPurchase(
            id: "d1",
            originalPriceBYN: 3_000,
            targetPriceUSD: 900,
            userNote: "торг",
            savedAt: 1
        )
        #expect(item.isTargetReached(currentBYN: 2_700, usdBYN: 3.0))
        #expect(!item.isTargetReached(currentBYN: 3_000, usdBYN: 3.0))
        #expect(item.usdToTarget(currentBYN: 3_000, usdBYN: 3.0) == 100)
    }
}

struct DeferredGarageModelTests {
    private func model(listings: [Listing]) -> AppModel {
        let defaults = UserDefaults(suiteName: "autora.deferred.\(UUID().uuidString)")!
        let seed = SeedFile(listings: listings, chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        return AppModel(seed: seed, defaults: defaults, now: { 1_000_000 })
    }

    @Test func toggleDeferredCapturesOriginalAndPersistsNoteAndTarget() {
        let listing = listingFixture(id: "lst-g", price: 2_990)
        let app = model(listings: [listing])
        app.toggleDeferred("lst-g")
        #expect(app.deferredPurchase(id: "lst-g")?.originalPriceBYN == 2_990)
        app.setDeferredNote("lst-g", "Звонил, отдал резину")
        app.setDeferredTargetUSD("lst-g", 900)
        let reloaded = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1_000_000 }
        )
        #expect(reloaded.deferredPurchase(id: "lst-g")?.userNote == "Звонил, отдал резину")
        #expect(reloaded.deferredPurchase(id: "lst-g")?.targetPriceUSD == 900)
        #expect(reloaded.isDeferred("lst-g"))
    }
}

struct VinReportTests {
    @Test func demoReportIsCleanAndHasHistory() {
        let report = VinReport.demo(vin: "X7LLG1234PA987654")
        #expect(report.vin == "X7LLG1234PA987654")
        #expect(report.wantedOK)
        #expect(report.liensOK)
        #expect(report.accidentsOK)
        #expect(report.ownersInBY == 1)
        #expect(report.safetyScore == 9.8)
        #expect(report.mileage.count == 3)
        #expect(report.registry.count == 2)
        #expect(report.mileage[0].km >= report.mileage[1].km)
    }

    @Test func samplesIncludeThreeDemoVins() {
        #expect(VinReport.samples.count == 3)
        #expect(VinReport.samples.contains { $0.vin.count == 17 })
    }
}

struct MarketDealTests {
    @Test func discountPercentAndRadarOrderHottestFirst() {
        let a4 = (1...5).map { listingFixture(id: "a\($0)", make: "Audi", model: "A4", year: 2018, price: 10_000) }
        let q5 = (1...5).map { listingFixture(id: "q\($0)", make: "Audi", model: "Q5", year: 2018, price: 10_000) }
        let hot = listingFixture(id: "hot", make: "Audi", model: "A4", year: 2018, price: 8_000)
        let mild = listingFixture(id: "mild", make: "Audi", model: "Q5", year: 2018, price: 9_000)
        let all = a4 + q5 + [hot, mild]
        #expect(MarketDeal.discountPercent(for: hot, in: all) == 20)
        #expect(MarketDeal.discountPercent(for: mild, in: all) == 10)
        #expect(MarketDeal.radar(in: all).map(\.id) == ["hot", "mild"])
    }

    @Test func lonelyListingHasNoDeal() {
        let lonely = listingFixture(id: "d")
        #expect(MarketDeal.discountPercent(for: lonely, in: [lonely]) == nil)
        #expect(MarketDeal.radar(in: [lonely]).isEmpty)
    }
}

struct CompareDeltaTests {
    @Test func deltaSummarizesPriceMileageAndYear() {
        let a = listingFixture(id: "a", year: 2020, price: 6_000, km: 40_000)
        let b = listingFixture(id: "b", year: 2018, price: 9_000, km: 90_000)
        let delta = CompareDelta.of(a, b, usdBYN: 3.0)
        #expect(delta.priceUSD == 1_000)
        #expect(delta.cheaperLabel == "Объявление №1 дешевле")
        #expect(delta.mileageKm == 50_000)
        #expect(delta.yearSummary == "2 г. разницы")
        #expect(!delta.isDuplicate)
    }

    @Test func duplicateAndSameYear() {
        let a = listingFixture(id: "same", year: 2020, price: 3_000, km: 10)
        #expect(CompareDelta.of(a, a, usdBYN: 3.0).isDuplicate)
        #expect(CompareDelta.of(a, listingFixture(id: "b", year: 2020, price: 3_000), usdBYN: 3.0).yearSummary == "Одного года")
    }
}

struct ListingLiquidityTests {
    @Test func daysToSellUsesValuationFormula() {
        let listing = listingFixture(make: "Geely", year: 2022, km: 45_000)
        let quote = MarketValuation.quote(
            make: "Geely",
            year: 2022,
            mileageKm: 45_000,
            condition: .good,
            usdBYN: 2.99,
            nowYear: 2026
        )
        #expect(ListingLiquidity.daysToSell(listing, usdBYN: 2.99) == quote.days)
    }
}

struct ListingSpecsTests {
    @Test func engineLineIncludesLitersFuelAndPower() {
        let listing = listingFixture(fuel: "дизель")
        #expect(ListingSpecs.engineLine(listing).contains("2.0"))
        #expect(ListingSpecs.engineLine(listing).contains("дизель"))
        #expect(ListingSpecs.engineLine(listing).contains("150"))
    }

    @Test func accelerationFallsAsPowerRises() {
        var weak = listingFixture()
        weak.powerHp = 110
        var strong = listingFixture()
        strong.powerHp = 300
        #expect(ListingSpecs.acceleration0100(strong) < ListingSpecs.acceleration0100(weak))
        #expect(ListingSpecs.equipment.count >= 8)
    }
}
