import Foundation

enum MarketValuation {
    enum Condition: String, Codable, CaseIterable, Identifiable, Sendable {
        case excellent, good, average
        var id: String { rawValue }
        var title: String {
            switch self {
            case .excellent: "Идеальное"
            case .good: "Хорошее"
            case .average: "Требует вложений"
            }
        }
    }

    struct Quote: Equatable, Sendable {
        var usd: Int
        var byn: Int
        var minUSD: Int
        var maxUSD: Int
        var days: Int
    }

    static func quote(
        make: String,
        year: Int,
        mileageKm: Int,
        condition: Condition,
        usdBYN: Double,
        nowYear: Int = 2026
    ) -> Quote {
        var base = 32_000.0
        switch make {
        case "Geely": base = 33_000
        case "BMW": base = 38_000
        case "Volkswagen": base = 27_000
        case "Tesla": base = 35_000
        case "Mercedes-Benz": base = 39_000
        case "Toyota": base = 32_500
        case "Li Auto": base = 45_000
        default: break
        }
        let diff = max(0, nowYear - year)
        let yearMod = max(0.4, 1 - Double(diff) * 0.075)
        let mileMod = max(0.65, 1 - (Double(mileageKm) / 100_000) * 0.12)
        let condMod: Double = switch condition {
        case .excellent: 1.06
        case .good: 1.0
        case .average: 0.92
        }
        let fair = (base * yearMod * mileMod * condMod).rounded()
        let usd = Int(fair)
        let extraDays = condition == .excellent ? 5 : 0
        return Quote(
            usd: usd,
            byn: Int((Double(usd) * usdBYN).rounded()),
            minUSD: Int((fair * 0.93).rounded()),
            maxUSD: Int((fair * 1.07).rounded()),
            days: max(8, 22 - extraDays + diff * 2)
        )
    }

    static func liquidityTitle(days: Int) -> String {
        switch days {
        case ...14: "высокая"
        case 15...22: "средняя"
        default: "ниже средней"
        }
    }
}

enum LeaseQuote {
    static func monthlyBYN(
        priceUSD: Double,
        downPercent: Int,
        years: Int,
        usdBYN: Double
    ) -> Int {
        let priceBYN = (priceUSD * usdBYN).rounded()
        let principal = priceBYN * (1 - Double(downPercent) / 100)
        let total = principal * (1 + 0.12 * Double(years))
        let months = Double(max(years, 1) * 12)
        return Int((total / months).rounded())
    }
}
