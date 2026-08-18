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

    @Test func ownedGarageSeedsDemoFleetWhenEmpty() {
        let app = model(listings: [])
        #expect(app.ownedGarage.count >= 1)
        #expect(app.ownedGarage.contains { $0.make == "Geely" })
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
