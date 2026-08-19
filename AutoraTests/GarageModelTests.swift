import Foundation
import Testing
@testable import Autora

struct GarageModelTests {
    private func model(listings: [Listing]) -> AppModel {
        let defaults = UserDefaults(suiteName: "autora.garage.\(UUID().uuidString)")!
        let seed = SeedFile(listings: listings, chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        return AppModel(seed: seed, defaults: defaults, now: { 1_000_000 })
    }

    @Test func toggleDeferredPersistsAndSurvivesReload() {
        let listing = listingFixture(id: "lst-g")
        let app = model(listings: [listing])
        #expect(!app.isDeferred("lst-g"))
        app.toggleDeferred("lst-g")
        #expect(app.isDeferred("lst-g"))
        let reloaded = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1_000_000 }
        )
        #expect(reloaded.isDeferred("lst-g"))
        reloaded.toggleDeferred("lst-g")
        #expect(!reloaded.isDeferred("lst-g"))
    }

    @Test func garageTabCountsAndHeadline() {
        let listing = listingFixture(id: "lst-g")
        #expect(
            GarageOverview.count(
                .favorites,
                favoriteIDs: ["lst-g"],
                listings: [listing],
                deferred: [],
                fleet: 2,
                searches: 0
            ) == 1
        )
        #expect(
            GarageOverview.count(
                .deferred,
                favoriteIDs: [],
                listings: [listing],
                deferred: [DeferredPurchase(id: "lst-g", originalPriceBYN: 100, targetPriceUSD: 90, userNote: "", savedAt: 1)],
                fleet: 0,
                searches: 3
            ) == 1
        )
        #expect(GarageOverview.headline(drops: 1, favorites: 2, fleet: 2) == "1 к цели · 2 в избранном · 2 своих")
        #expect(GarageOverview.headline(drops: 0, favorites: 0, fleet: 0).contains("Пусто"))
        #expect(GarageTab.allCases.map(\.title) == ["Избранное", "Отложенные", "Автопарк", "Поиски"])
        #expect(GarageOverview.carTotal(favorites: 2, deferred: 1, fleet: 3) == 6)
    }

    @Test func garageTabSurvivesReload() {
        let app = model(listings: [])
        app.garageTab = .fleet
        let reloaded = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1_000_000 }
        )
        #expect(reloaded.garageTab == .fleet)
    }

    @Test func ownedGarageStartsEmptyWithoutDemoFleet() {
        let app = model(listings: [])
        #expect(app.ownedGarage.isEmpty)
        #expect(!app.ownedGarage.contains { $0.make == "Geely" })
        #expect(OwnedGarageCar.demoFleet.count == 2)
    }

    @Test func addAndRemoveOwnedCarPersists() {
        let app = model(listings: [])
        let start = app.ownedGarage.count
        let car = OwnedGarageCar(
            id: "gar-test",
            make: "Mazda",
            model: "6",
            year: 2018,
            currentValueUSD: 12_000,
            currentValueBYN: 35_880,
            monthlyChangeUSD: 10,
            mileageKm: 90_000,
            nextMotDate: "01.01.2027",
            nextInsuranceDate: "01.01.2027",
            nextOilServiceKm: 95_000,
            city: "Минск",
            engine: "2.0"
        )
        app.addOwned(car)
        #expect(app.ownedGarage.count == start + 1)
        app.removeOwned("gar-test")
        #expect(!app.ownedGarage.contains { $0.id == "gar-test" })
        let reloaded = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: app.defaults,
            now: { 1_000_000 }
        )
        #expect(!reloaded.ownedGarage.contains { $0.id == "gar-test" })
    }
}
