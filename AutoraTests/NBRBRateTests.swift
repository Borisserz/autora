import Foundation
import Testing
@testable import Autora

struct NBRBRateTests {
    @Test func parseOfficialRateDividedByScale() throws {
        let json = Data(#"{"Cur_OfficialRate":6.44,"Cur_Scale":2}"#.utf8)
        #expect(try NBRBRate.parse(json) == 3.22)
        let usd = Data(#"{"Cur_OfficialRate":3.2721,"Cur_Scale":1}"#.utf8)
        #expect(try NBRBRate.parse(usd) == 3.2721)
    }

    @Test func pickPrefersFetchedThenCacheThenSeed() {
        #expect(NBRBRate.pick(fetched: 3.2, cached: 3.1, seed: 2.99) == FXRate(usdBYN: 3.2, source: .nbrb))
        #expect(NBRBRate.pick(fetched: nil, cached: 3.1, seed: 2.99) == FXRate(usdBYN: 3.1, source: .cache))
        #expect(NBRBRate.pick(fetched: nil, cached: nil, seed: 2.99) == FXRate(usdBYN: 2.99, source: .seed))
        #expect(NBRBRate.pick(fetched: 0, cached: 3.1, seed: 2.99).source == .cache)
    }

    @Test func cachedRateSurvivesReloadWithoutNetwork() {
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        defaults.set(3.15, forKey: "autora.fxCache")
        let app = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        #expect(app.fx.usdBYN == 3.15)
        #expect(app.fx.source == .cache)
        #expect(app.fx.source.caption.contains("кэш"))
    }

    @Test func applyCatalogDoesNotOverwriteCachedRate() {
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        defaults.set(3.15, forKey: "autora.fxCache")
        let app = AppModel(
            seed: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        app.applyCatalog(SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.50)))
        #expect(app.fx.usdBYN == 3.15)
        #expect(app.fx.source == .cache)
    }
}
