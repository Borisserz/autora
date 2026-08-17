import Foundation
import Testing
@testable import Autora

struct FilterCatalogTests {
    let sample: [Listing] = {
        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let seedURL = tests.deletingLastPathComponent().appending(path: "Autora/Resources/seed.json")
        return (try? SeedLoader.load(from: seedURL))?.listings ?? []
    }()

    private var catalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Autora/Resources/catalog.json")
    }

    @Test func makesIncludeVolkswagenSorted() {
        #expect(!sample.isEmpty)
        let makes = FilterCatalog.makes(in: sample)
        #expect(makes.contains("Volkswagen"))
        #expect(makes.contains("Audi"))
        #expect(makes == makes.sorted())
        #expect(Set(makes).count == makes.count)
    }

    @Test func volkswagenModelsIncludePassat() {
        let models = FilterCatalog.models(in: sample, make: "Volkswagen")
        #expect(models.contains("Passat"))
        #expect(models == models.sorted())
    }

    @Test func unknownMakeHasNoModels() {
        #expect(FilterCatalog.models(in: sample, make: "НетТакойМарки").isEmpty)
    }

    @Test func passatGenerationsIncludeB8() {
        let gens = FilterCatalog.generations(in: sample, make: "Volkswagen", model: "Passat")
        #expect(gens.contains("B8"))
    }

    @Test func seedListingsAreNotExpiredInAugust2026() {
        let now: TimeInterval = 1_786_982_400
        #expect(sample.contains { !BumpPolicy.isExpired(bumpedAt: $0.bumpedAt, now: now) })
        let active = sample.filter { $0.status == .active }
        #expect(active.allSatisfy { !BumpPolicy.isExpired(bumpedAt: $0.bumpedAt, now: now) })
    }

    @Test func seedSavedSearchDecodesFlatJSON() throws {
        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let seedURL = tests.deletingLastPathComponent().appending(path: "Autora/Resources/seed.json")
        let seed = try SeedLoader.load(from: seedURL)
        #expect(seed.savedSearches.contains { $0.model == "Passat" })
    }

    @Test func catalogProvidesModelsWithoutSeedListings() throws {
        let catalog = try VehicleCatalog.load(from: catalogURL)
        #expect(catalog.makes.contains { $0.name == "Mazda" })
        let models = FilterCatalog.modelsForPost(in: [], make: "Mazda", catalog: catalog)
        #expect(models.contains("CX-5"))
        let gens = FilterCatalog.generationsForPost(in: [], make: "Volkswagen", model: "Passat", catalog: catalog)
        #expect(gens.contains("B8"))
    }

    @Test func seedChatDecodesWithoutParticipantIds() throws {
        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let seedURL = tests.deletingLastPathComponent().appending(path: "Autora/Resources/seed.json")
        let seed = try SeedLoader.load(from: seedURL)
        #expect(seed.chats.contains { $0.id == "chat-001" && $0.participantIds.isEmpty })
    }

    @Test func bodiesAndCitiesFromSeed() {
        let bodies = FilterCatalog.bodies(in: sample)
        let cities = FilterCatalog.cities(in: sample)
        #expect(bodies.contains("седан"))
        #expect(cities.contains("Минск"))
        #expect(bodies == bodies.sorted())
        #expect(cities == cities.sorted())
    }
}

struct CompareSetTests {
    @Test func addsUntilThreeThenIgnores() {
        var ids: [String] = []
        ids = CompareSet.toggling("a", in: ids)
        ids = CompareSet.toggling("b", in: ids)
        ids = CompareSet.toggling("c", in: ids)
        #expect(ids == ["a", "b", "c"])
        ids = CompareSet.toggling("d", in: ids)
        #expect(ids == ["a", "b", "c"])
    }

    @Test func togglingExistingRemoves() {
        let ids = CompareSet.toggling("b", in: ["a", "b", "c"])
        #expect(ids == ["a", "c"])
    }
}

struct SavedSearchFactoryTests {
    @Test func titleFromMakeModelCity() {
        var criteria = SearchCriteria()
        criteria.make = "Volkswagen"
        criteria.model = "Passat"
        criteria.city = "Минск"
        let search = SavedSearch.from(criteria: criteria, id: "ss-test")
        #expect(search.title == "Volkswagen · Passat · Минск")
        #expect(search.make == "Volkswagen")
        #expect(search.model == "Passat")
        #expect(search.city == "Минск")
    }

    @Test func emptyCriteriaTitle() {
        let search = SavedSearch.from(criteria: SearchCriteria(), id: "empty")
        #expect(search.title == "Все объявления")
    }

    @Test func queryOnlyUsesQuery() {
        var criteria = SearchCriteria()
        criteria.query = "passat"
        #expect(SavedSearch.from(criteria: criteria, id: "q").title == "passat")
    }

    @Test func duplicateIgnoresIdAndTitle() {
        let a = SavedSearch.from(
            criteria: {
                var c = SearchCriteria()
                c.make = "Volkswagen"
                c.model = "Passat"
                c.priceTo = 20000
                c.city = "Минск"
                return c
            }(),
            id: "1"
        )
        let b = SavedSearch(id: "2", title: "B", criteria: a.criteria)
        #expect(a.isDuplicate(of: b))
        var audi = SearchCriteria()
        audi.make = "Audi"
        #expect(!a.isDuplicate(of: SavedSearch(id: "3", title: "C", criteria: audi)))
    }
}

struct ListingCaptionTests {
    @Test func specLineUsesCatalogSeparators() {
        let listing = listingFixture(year: 2018, km: 145_000)
        #expect(listing.specLine.contains("2018"))
        #expect(listing.specLine.contains("·"))
        #expect(listing.specLine.contains("автомат"))
        #expect(!listing.specLine.contains("г.,"))
    }

    @Test func specLineIncludesGeneration() {
        let listing = listingFixture(generation: "B8")
        #expect(listing.specLine.contains("B8"))
    }

    @Test func hasVINWhenPresent() {
        #expect(!listingFixture(vin: nil).hasVIN)
        #expect(listingFixture(vin: "WVWZZZ00000000000").hasVIN)
        #expect(!listingFixture(vin: "  ").hasVIN)
    }
}
