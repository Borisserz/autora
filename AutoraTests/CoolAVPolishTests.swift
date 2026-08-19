import Foundation
import Testing
@testable import Autora

struct BelarusPhoneTests {
    @Test func formatsLocalNineDigits() {
        #expect(BelarusPhone.display("291112233") == "+375 (29) 111-22-33")
    }

    @Test func formatsInternationalAndLegacy80() {
        #expect(BelarusPhone.display("375291112233") == "+375 (29) 111-22-33")
        #expect(BelarusPhone.display("80291112233") == "+375 (29) 111-22-33")
        #expect(BelarusPhone.display("+375 (29) 111-22-33") == "+375 (29) 111-22-33")
    }

    @Test func telURLStillWorksOnMaskedPhone() {
        #expect(PhoneLink.telURL(BelarusPhone.display("375291112233"))?.absoluteString == "tel:+375291112233")
        #expect(BelarusPhone.e164("+375 (29) 111-22-33") == "+375291112233")
    }
}

struct ListingDraftPriceTests {
    @Test func suggestedQuoteMatchesValuationAndAppliesBYN() {
        var draft = ListingDraft()
        draft.make = "Geely"
        draft.year = 2022
        draft.mileageKm = 45_000
        let quote = draft.suggestedQuote(usdBYN: 2.99, nowYear: 2026)
        #expect(quote.usd == 21_853)
        #expect(quote.byn == 65_340)
        draft.applySuggestedPrice(usdBYN: 2.99, nowYear: 2026)
        #expect(draft.priceBYN == 65_340)
    }
}

struct PhotoGalleryTests {
    @Test func firstFourHaveNamedCaptionsThenFallback() {
        #expect(PhotoGallery.caption(index: 0, count: 4) == "Экстерьер")
        #expect(PhotoGallery.caption(index: 1, count: 4) == "Интерьер и руль")
        #expect(PhotoGallery.caption(index: 2, count: 4) == "Второй ряд")
        #expect(PhotoGallery.caption(index: 3, count: 4) == "Диски и оптика")
        #expect(PhotoGallery.caption(index: 4, count: 6) == "Фото 5")
    }
}

struct OwnedGaragePlateTests {
    @Test func demoFleetUsesSitePlates() {
        #expect(OwnedGarageCar.demoFleet.map(\.licensePlate) == ["7788 AB-7", "1234 MI-7"])
    }
}

struct ModelInsightTests {
    @Test func geelyScoresHighLiquidity() {
        let insight = ModelInsight.lookup(make: "Geely")
        #expect(insight.tag == "Топ-ликвидность в РБ")
        #expect(insight.overall == 9.4)
        #expect(insight.monthlyUSD == 190)
        #expect(insight.parts == 9.8)
        #expect(insight.comfort == 9.2)
        #expect(insight.reliability == 9.1)
        #expect(insight.pros.count == 4)
        #expect(insight.cons.count == 2)
        #expect(insight.weakSpots.contains("круиза"))
        #expect(!insight.idealFor.isEmpty)
    }

    @Test func catalogHasEightCoolAVModelsAndPrefersModelMatch() {
        #expect(ModelInsight.catalog.count == 8)
        #expect(ModelInsight.lookup(make: "BMW", model: "5-Series").id == "bmw-5-g30")
        #expect(ModelInsight.lookup(make: "Volkswagen").liquidityDays == 12)
    }

    @Test func catalogCopyDoesNotMentionAvBy() {
        let blob = ModelInsight.catalog
            .flatMap { [$0.tag] + $0.pros + $0.cons + [$0.idealFor, $0.weakSpots] }
            .joined()
            .lowercased()
        #expect(!blob.contains("av.by"))
        #expect(!blob.contains("avby"))
    }

    @Test func unknownMakeFallsBack() {
        let insight = ModelInsight.lookup(make: "НетТакой")
        #expect(insight.overall == 8.5)
        #expect(insight.pros.isEmpty)
    }
}
