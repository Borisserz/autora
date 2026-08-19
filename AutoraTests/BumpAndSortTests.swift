import Foundation
import Testing
@testable import Autora

struct BumpPolicyTests {
    @Test func cannotBumpBefore20Hours() {
        let t: TimeInterval = 1_000_000
        #expect(BumpPolicy.canBump(lastBumped: t, now: t + 19 * 3600) == false)
    }

    @Test func canBumpAfter20Hours() {
        let t: TimeInterval = 1_000_000
        #expect(BumpPolicy.canBump(lastBumped: t, now: t + 20 * 3600) == true)
    }

    @Test func hoursUntilBumpRoundsUp() {
        let t: TimeInterval = 1_000_000
        #expect(BumpPolicy.hoursUntilBump(lastBumped: t, now: t + 19 * 3600) == 1)
        #expect(BumpPolicy.hoursUntilBump(lastBumped: t, now: t + 20 * 3600) == 0)
    }

    @Test func demoListingsNeverExpire() {
        let t: TimeInterval = BumpPolicy.lifetime + 1
        #expect(BumpPolicy.isExpired(bumpedAt: 0, now: t, isDemo: true) == false)
        #expect(BumpPolicy.isExpired(bumpedAt: 0, now: t, isDemo: false) == true)
    }
}

struct ListingSortTests {
    @Test func cheapestOrdersAscending() {
        let a = fixture(id: "a", price: 300, bumped: 2, km: 10)
        let b = fixture(id: "b", price: 100, bumped: 1, km: 50)
        let c = fixture(id: "c", price: 200, bumped: 3, km: 5)
        #expect(ListingSort.cheapest.apply([a, b, c]).map(\.id) == ["b", "c", "a"])
        #expect(ListingSort.newest.apply([a, b, c]).first?.id == "c")
        #expect(ListingSort.mileage.apply([a, b, c]).first?.id == "c")
    }
}

struct MarketPriceTests {
    @Test func badgeNeedsPeers() {
        let a = fixture(id: "a", price: 100, bumped: 1, km: 1, make: "Audi")
        #expect(MarketPrice.badge(for: a, in: [a]) == nil)
        let peers = (1...5).map { fixture(id: "p\($0)", price: 100, bumped: 1, km: 1, make: "Audi") }
        let cheap = fixture(id: "d", price: 50, bumped: 1, km: 1, make: "Audi")
        #expect(MarketPrice.badge(for: a, in: [a]) == nil)
        #expect(MarketPrice.badge(for: cheap, in: peers + [cheap]) == "ниже рынка")
        #expect(MarketPrice.caption("ниже рынка") == "ниже рынка · по выборке CoolAV")
    }

    @Test func badgeIgnoresPeersOutsideYearWindow() {
        let target = fixture(id: "d", price: 50, bumped: 1, km: 1, make: "Audi", year: 2018)
        let far = (1...5).map { fixture(id: "p\($0)", price: 100, bumped: 1, km: 1, make: "Audi", year: 2010) }
        #expect(MarketPrice.badge(for: target, in: far + [target]) == nil)
        let near = (1...5).map { fixture(id: "n\($0)", price: 100, bumped: 1, km: 1, make: "Audi", year: 2017) }
        #expect(MarketPrice.badge(for: target, in: near + [target]) == "ниже рынка")
    }
}

private func fixture(
    id: String,
    price: Int,
    bumped: TimeInterval,
    km: Int,
    make: String = "VW",
    year: Int = 2018
) -> Listing {
    Listing(
        id: id,
        sellerId: "s",
        sellerName: "S",
        sellerPhone: "+37529",
        sellerListingCount: 1,
        make: make,
        model: "A4",
        generation: nil,
        year: year,
        priceBYN: price,
        mileageKm: km,
        body: "седан",
        fuel: "бензин",
        transmission: "автомат",
        drivetrain: "передний",
        engineLiters: 2.0,
        powerHp: 150,
        city: "Минск",
        region: "Минская",
        condition: .used,
        registered: true,
        customsCleared: true,
        wheel: .left,
        hasPhotos: true,
        bargaining: false,
        exchange: false,
        forParts: false,
        damaged: false,
        vin: nil,
        isTop: false,
        isDemo: true,
        status: .active,
        photoURLs: [],
        description: "",
        views: 0,
        favoritesCount: 0,
        phoneReveals: 0,
        bumpedAt: bumped,
        createdAt: bumped
    )
}
