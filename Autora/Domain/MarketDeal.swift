import Foundation

enum MarketDeal {
    static func discountPercent(for listing: Listing, in all: [Listing]) -> Int? {
        guard let avg = MarketPrice.peerAverageBYN(for: listing, in: all), avg > 0 else { return nil }
        guard listing.priceBYN < Int(Double(avg) * 0.92) else { return nil }
        let delta = avg - listing.priceBYN
        return Int((Double(delta) / Double(avg) * 100).rounded())
    }

    static func radar(in listings: [Listing]) -> [Listing] {
        listings
            .filter { $0.status == .active && discountPercent(for: $0, in: listings) != nil }
            .sorted {
                (discountPercent(for: $0, in: listings) ?? 0) > (discountPercent(for: $1, in: listings) ?? 0)
            }
    }
}

enum ListingLiquidity {
    static func daysToSell(_ listing: Listing, usdBYN: Double) -> Int {
        MarketValuation.quote(
            make: listing.make,
            year: listing.year,
            mileageKm: listing.mileageKm,
            condition: .good,
            usdBYN: usdBYN
        ).days
    }
}

enum ListingSpecs {
    static func engineLine(_ listing: Listing) -> String {
        let liters = String(format: "%.1f", listing.engineLiters)
        return "\(liters) л · \(listing.fuel) (\(listing.powerHp) л.с.)"
    }

    static func acceleration0100(_ listing: Listing) -> Double {
        let raw = 12.5 - Double(listing.powerHp) / 40.0
        return (max(4.2, raw) * 10).rounded() / 10
    }

    static let equipment: [String] = [
        "Панорамная крыша с люком",
        "Камеры кругового обзора 360°",
        "Адаптивный круиз-контроль",
        "Вентиляция и подогрев сидений",
        "Матричная оптика LED",
        "Проекция на лобовое стекло",
        "Apple CarPlay и Android Auto",
        "Премиум акустика",
        "Система удержания в полосе",
        "Беспроводная зарядка",
        "Электропривод багажника",
        "Двухзонный климат-контроль"
    ]
}

struct CompareDelta: Equatable, Sendable {
    var priceUSD: Int
    var cheaperLabel: String
    var mileageKm: Int
    var yearSummary: String
    var isDuplicate: Bool

    static func of(_ first: Listing, _ second: Listing, usdBYN: Double) -> CompareDelta {
        let a = PriceConverter.filterUSD(fromBYN: first.priceBYN, rate: usdBYN)
        let b = PriceConverter.filterUSD(fromBYN: second.priceBYN, rate: usdBYN)
        let cheaper: String
        if a == b {
            cheaper = "Цена одинаковая"
        } else if a < b {
            cheaper = "Объявление №1 дешевле"
        } else {
            cheaper = "Объявление №2 дешевле"
        }
        let years = abs(first.year - second.year)
        let yearSummary = years == 0 ? "Одного года" : "\(years) г. разницы"
        return CompareDelta(
            priceUSD: abs(a - b),
            cheaperLabel: cheaper,
            mileageKm: abs(first.mileageKm - second.mileageKm),
            yearSummary: yearSummary,
            isDuplicate: first.id == second.id
        )
    }
}
