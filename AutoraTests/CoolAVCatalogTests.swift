import Foundation
import Testing
@testable import Autora

struct ListingCategoryTests {
    @Test func allMatchesEverything() {
        let car = listingFixture(id: "a", fuel: "бензин")
        #expect(ListingCategoryTab.all.matches(car, in: [car]))
    }

    @Test func evMatchesHybridAndElectricFuel() {
        let hybrid = listingFixture(id: "h", fuel: "гибрид")
        let petrol = listingFixture(id: "p", fuel: "бензин")
        let ev = listingFixture(id: "e", fuel: "электро")
        #expect(ListingCategoryTab.ev.matches(hybrid, in: [hybrid]))
        #expect(ListingCategoryTab.ev.matches(ev, in: [ev]))
        #expect(!ListingCategoryTab.ev.matches(petrol, in: [petrol]))
    }

    @Test func europeMatchesGermanMakesWhenCleared() {
        let bmw = listingFixture(id: "b", make: "BMW", customsCleared: true)
        let geely = listingFixture(id: "g", make: "Geely", customsCleared: true)
        #expect(ListingCategoryTab.europe.matches(bmw, in: [bmw]))
        #expect(!ListingCategoryTab.europe.matches(geely, in: [geely]))
    }

    @Test func warrantyMatchesTopOrRecentYear() {
        let top = listingFixture(id: "t", year: 2018, isTop: true)
        let fresh = listingFixture(id: "f", year: 2024, isTop: false)
        let old = listingFixture(id: "o", year: 2016, isTop: false)
        #expect(ListingCategoryTab.warranty.matches(top, in: [top]))
        #expect(ListingCategoryTab.warranty.matches(fresh, in: [fresh]))
        #expect(!ListingCategoryTab.warranty.matches(old, in: [old]))
    }

    @Test func premiumMatchesLuxuryMakeOrHighUSD() {
        let mercedes = listingFixture(id: "m", make: "Mercedes-Benz", price: 10_000)
        let cheapVW = listingFixture(id: "v", make: "Volkswagen", price: 5_000)
        let pricey = listingFixture(id: "x", make: "Geely", price: 150_000)
        #expect(ListingCategoryTab.premium.matches(mercedes, in: [mercedes], usdBYN: 2.99))
        #expect(!ListingCategoryTab.premium.matches(cheapVW, in: [cheapVW], usdBYN: 2.99))
        #expect(ListingCategoryTab.premium.matches(pricey, in: [pricey], usdBYN: 2.99))
    }

    @Test func bargainMatchesBelowMarketOrBargainingFlag() {
        let deal = listingFixture(id: "d", make: "Audi", price: 50, bargaining: true)
        #expect(ListingCategoryTab.bargain.matches(deal, in: [deal]))
        let peers = (1...5).map { listingFixture(id: "p\($0)", make: "Audi", price: 100) }
        let cheap = listingFixture(id: "c", make: "Audi", price: 50)
        #expect(ListingCategoryTab.bargain.matches(cheap, in: peers + [cheap]))
    }

    @Test func filterAppliesCategoryAfterCriteria() {
        var criteria = SearchCriteria()
        criteria.category = .ev
        let listings = [
            listingFixture(id: "h", fuel: "гибрид"),
            listingFixture(id: "p", fuel: "бензин")
        ]
        #expect(ListingFilter.apply(criteria, to: listings).map(\.id) == ["h"])
    }
}

struct CoolAVCopyTests {
    @Test func tickerNeverMentionsAvBy() {
        for line in CoolAVCopy.ticker {
            #expect(!line.lowercased().contains("av.by"))
            #expect(!line.lowercased().contains("avby"))
        }
    }

    @Test func categoryChipTitlesMatchSite() {
        #expect(ListingCategoryTab.bargain.chipTitle.contains("-10%"))
        #expect(ListingCategoryTab.ev.chipTitle == "Электромобили")
        #expect(ListingCategoryTab.europe.chipTitle == "Из Германии")
        #expect(ListingCategoryTab.premium.catalogTitle == "Премиум класс")
    }
}
