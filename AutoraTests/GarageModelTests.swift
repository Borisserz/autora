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
}
