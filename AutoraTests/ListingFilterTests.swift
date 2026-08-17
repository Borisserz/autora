import Foundation
import Testing
@testable import Autora

struct ListingFilterTests {
    let sample: [Listing] = {
        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let seedURL = tests.deletingLastPathComponent().appending(path: "Autora/Resources/seed.json")
        return (try? SeedLoader.load(from: seedURL))?.listings ?? []
    }()

    @Test func hideSoldRemovesSold() {
        #expect(!sample.isEmpty)
        let result = ListingFilter.apply(SearchCriteria(hideSold: true), to: sample)
        #expect(result.allSatisfy { $0.status == .active })
        #expect(result.count < sample.count)
    }

    @Test func filterByMake() {
        var c = SearchCriteria()
        c.make = "Volkswagen"
        let result = ListingFilter.apply(c, to: sample)
        #expect(!result.isEmpty)
        #expect(result.allSatisfy { $0.make == "Volkswagen" })
    }

    @Test func filterByModelAndGeneration() {
        var c = SearchCriteria()
        c.make = "Volkswagen"
        c.model = "Passat"
        c.generation = "B8"
        let result = ListingFilter.apply(c, to: sample)
        #expect(!result.isEmpty)
        #expect(result.allSatisfy { $0.make == "Volkswagen" && $0.model == "Passat" && $0.generation == "B8" })
    }

    @Test func modelCountsFollowSelectedMake() {
        let counts = BrandCounter.modelCounts(in: sample, make: "Volkswagen")
        #expect(counts.contains { $0.name == "Passat" && $0.count > 0 })
        #expect(!counts.contains { $0.name == "A6" })
    }

    @Test func generationCountsFollowSelectedModel() {
        let counts = BrandCounter.generationCounts(in: sample, make: "Volkswagen", model: "Passat")
        #expect(counts.contains { $0.name == "B8" && $0.count > 0 })
    }

    @Test func queryMatchesModel() {
        var c = SearchCriteria()
        c.query = "passat"
        let result = ListingFilter.apply(c, to: sample)
        #expect(!result.isEmpty)
        #expect(result.allSatisfy { $0.model.lowercased().contains("passat") })
    }

    @Test func queryMatchesCity() {
        var c = SearchCriteria()
        c.query = "гродно"
        let listings = [
            listingFixture(id: "a", city: "Гродно"),
            listingFixture(id: "b", city: "Минск")
        ]
        #expect(ListingFilter.apply(c, to: listings).map(\.id) == ["a"])
    }

    @Test func rightHandDrive() {
        var c = SearchCriteria()
        c.wheel = .right
        c.hideSold = false
        let result = ListingFilter.apply(c, to: sample)
        #expect(result.contains { $0.wheel == .right })
    }

    @Test func uncustomed() {
        var c = SearchCriteria()
        c.customsCleared = false
        c.hideSold = false
        let result = ListingFilter.apply(c, to: sample)
        #expect(!result.isEmpty)
        #expect(result.allSatisfy { $0.customsCleared == false })
    }

    @Test func defaultCriteriaHasNoActiveFilters() {
        #expect(SearchCriteria().activeFilterCount == 0)
    }

    @Test func countsMakeQueryAndShownSold() {
        var c = SearchCriteria()
        c.make = "Audi"
        c.query = "a4"
        c.hideSold = false
        #expect(c.activeFilterCount == 3)
    }
}
