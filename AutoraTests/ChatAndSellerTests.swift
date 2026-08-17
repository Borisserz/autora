import Foundation
import Testing
@testable import Autora

struct ChatDraftTests {
    @Test func rejectsBlank() {
        #expect(ChatDraft.normalized("   ") == nil)
        #expect(ChatDraft.normalized("\n") == nil)
    }

    @Test func trimsMessage() {
        #expect(ChatDraft.normalized("  привет  ") == "привет")
    }
}

struct PhoneLinkTests {
    @Test func buildsTelURL() {
        #expect(PhoneLink.telURL("+375291112233")?.absoluteString == "tel:+375291112233")
    }

    @Test func emptyPhoneIsNil() {
        #expect(PhoneLink.telURL("") == nil)
        #expect(PhoneLink.telURL("abc") == nil)
    }
}

struct SellerStatsTests {
    @Test func sumsViewsFavoritesAndCalls() {
        let a = fixtureListing(id: "a", views: 10, favorites: 2, calls: 1)
        let b = fixtureListing(id: "b", views: 5, favorites: 3, calls: 4)
        let stats = SellerStats.from([a, b])
        #expect(stats.listingCount == 2)
        #expect(stats.views == 15)
        #expect(stats.favorites == 5)
        #expect(stats.phoneReveals == 5)
    }
}

private func fixtureListing(id: String, views: Int, favorites: Int, calls: Int) -> Listing {
    Listing(
        id: id,
        sellerId: "s",
        sellerName: "S",
        sellerPhone: "+37529",
        sellerListingCount: 1,
        make: "VW",
        model: "Passat",
        generation: nil,
        year: 2018,
        priceBYN: 100,
        mileageKm: 1,
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
        views: views,
        favoritesCount: favorites,
        phoneReveals: calls,
        bumpedAt: 1,
        createdAt: 1
    )
}
