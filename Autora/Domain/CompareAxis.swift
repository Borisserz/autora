import Foundation

enum CompareAxis {
    static func cheaper(_ listings: [Listing]) -> String? {
        winner(listings, value: \.priceBYN, preferLower: true)
    }

    static func newer(_ listings: [Listing]) -> String? {
        winner(listings, value: \.year, preferLower: false)
    }

    static func fewerKm(_ listings: [Listing]) -> String? {
        winner(listings, value: \.mileageKm, preferLower: true)
    }

    private static func winner(
        _ listings: [Listing],
        value: KeyPath<Listing, Int>,
        preferLower: Bool
    ) -> String? {
        guard listings.count >= 2 else { return nil }
        let sorted = listings.sorted {
            preferLower ? $0[keyPath: value] < $1[keyPath: value] : $0[keyPath: value] > $1[keyPath: value]
        }
        guard sorted[0][keyPath: value] != sorted[1][keyPath: value] else { return nil }
        return sorted[0].id
    }
}
