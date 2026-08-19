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
    @Test func captionsAreOrdinalNotGuessedShots() {
        #expect(PhotoGallery.caption(index: 0, count: 4) == "Фото 1 из 4")
        #expect(PhotoGallery.caption(index: 1, count: 4) == "Фото 2 из 4")
        #expect(PhotoGallery.caption(index: 4, count: 6) == "Фото 5 из 6")
    }
}

struct OwnedGaragePlateTests {
    @Test func demoFleetUsesSitePlates() {
        #expect(OwnedGarageCar.demoFleet.map(\.licensePlate) == ["7788 AB-7", "1234 MI-7"])
    }
}

struct ModelInsightTests {
    @Test func geelyMonjaroMatchesExactModel() {
        let insight = ModelInsight.lookup(make: "Geely", model: "Monjaro", year: 2023)
        #expect(insight?.id == "geely-monjaro")
        #expect(insight?.tag == "Топ-ликвидность в РБ")
        #expect(insight?.overall == 9.4)
        #expect(insight?.monthlyUSD == 190)
        #expect(insight?.parts == 9.8)
        #expect(insight?.pros.count == 4)
        #expect(insight?.weakSpots.contains("круиза") == true)
    }

    @Test func catalogHasEightCoolAVModelsAndPrefersModelMatch() {
        #expect(ModelInsight.catalog.count == 8)
        #expect(ModelInsight.lookup(make: "BMW", model: "5-Series", year: 2020)?.id == "bmw-5-g30")
        #expect(ModelInsight.lookup(make: "Volkswagen", model: "Tiguan")?.liquidityDays == 12)
    }

    @Test func makeOnlyAndWrongModelDoNotGuess() {
        #expect(ModelInsight.lookup(make: "Geely") == nil)
        #expect(ModelInsight.lookup(make: "Volkswagen", model: "Passat") == nil)
        #expect(ModelInsight.lookup(make: "BMW", model: "X3") == nil)
    }

    @Test func oldGenerationDoesNotGetCurrentCatalogCard() {
        #expect(ModelInsight.lookup(make: "Audi", model: "A6", year: 2009) == nil)
        #expect(ModelInsight.lookup(make: "Audi", model: "A6", year: 2021)?.id == "audi-a6-c8")
    }

    @Test func typicalForMakeIsExplicitCatalogPick() {
        #expect(ModelInsight.typical(forMake: "Geely")?.id == "geely-monjaro")
        #expect(ModelInsight.typical(forMake: "НетТакой") == nil)
    }

    @Test func catalogCopyDoesNotMentionAvBy() {
        let blob = ModelInsight.catalog
            .flatMap { [$0.tag] + $0.pros + $0.cons + [$0.idealFor, $0.weakSpots] }
            .joined()
            .lowercased()
        #expect(!blob.contains("av.by"))
        #expect(!blob.contains("avby"))
    }
}

struct ListingTrustTests {
    @Test func verifiedSealOnlyForTopListings() {
        #expect(!ListingTrust.showsVerifiedSeal(listingFixture(isTop: false)))
        #expect(ListingTrust.showsVerifiedSeal(listingFixture(isTop: true)))
        #expect(!ListingTrust.showsSyntheticEquipment(listingFixture()))
    }

    @Test func insightUsesExactModelNotMakeFallback() {
        let passat = listingFixture(make: "Volkswagen", model: "Passat", year: 2018)
        let tiguan = listingFixture(make: "Volkswagen", model: "Tiguan", year: 2021)
        #expect(ListingTrust.insight(for: passat) == nil)
        #expect(ListingTrust.insight(for: tiguan)?.id == "vw-tiguan")
    }
}
