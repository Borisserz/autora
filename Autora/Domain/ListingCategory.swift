import Foundation

enum ListingCategoryTab: String, CaseIterable, Identifiable, Sendable, Codable, Hashable {
    case all, bargain, ev, europe, warranty, premium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Все авто"
        case .bargain: "Выгодная цена"
        case .ev: "Электро и гибриды"
        case .europe: "Из Европы"
        case .warranty: "С гарантией"
        case .premium: "Премиум"
        }
    }

    var chipTitle: String {
        switch self {
        case .all: "Все авто"
        case .bargain: "Выгодная цена (-10%)"
        case .ev: "Электромобили"
        case .europe: "Из Германии"
        case .warranty: "С гарантией"
        case .premium: "Премиум класс"
        }
    }

    var catalogTitle: String {
        switch self {
        case .all: "Все авто"
        case .bargain: "Выгодная цена (-10%)"
        case .ev: "Электро и гибриды"
        case .europe: "Из Европы"
        case .warranty: "С гарантией дилера"
        case .premium: "Премиум класс"
        }
    }

    private static let europeanMakes: Set<String> = [
        "BMW", "Mercedes-Benz", "Mercedes", "Audi", "Volkswagen", "Porsche", "Opel"
    ]
    private static let luxuryMakes: Set<String> = [
        "BMW", "Mercedes-Benz", "Mercedes", "Audi", "Porsche", "Tesla", "Lexus"
    ]

    func matches(_ listing: Listing, in all: [Listing], usdBYN: Double = 2.99) -> Bool {
        switch self {
        case .all:
            return true
        case .bargain:
            if listing.bargaining { return true }
            return MarketPrice.badge(for: listing, in: all) == "ниже рынка"
        case .ev:
            let fuel = listing.fuel.lowercased()
            return fuel.contains("гибрид") || fuel.contains("электро") || fuel.contains("hybrid")
                || fuel.contains("ev") || fuel.contains("phev")
        case .europe:
            return listing.customsCleared && Self.europeanMakes.contains(listing.make)
        case .warranty:
            return listing.isTop || listing.year >= 2023
        case .premium:
            if Self.luxuryMakes.contains(listing.make) { return true }
            let usd = PriceConverter.usd(fromBYN: listing.priceBYN, rate: usdBYN)
            return usd >= 40_000
        }
    }
}

enum CoolAVCopy {
    static let brand = "CoolAV"
    static let wordmark = "CoolAV.by"
    static let heroBadge = "Автомобильный портал нового поколения с AI-аналитикой"
    static let heroTitle = "Умная покупка, продажа и аналитика авто в Беларуси"
    static let heroSubtitle = "Сравнивайте реальные цены, откладывайте машины в персональный гараж с трекингом скидок, сопоставляйте авто лоб в лоб и проверяйте историю по VIN."
    static let searchPlaceholder = "Быстрый поиск по марке, модели, кузову, городу или опциям..."
    static let catalogEyebrow = "Объявления с проверкой"
    static let catalogTitle = "Проверенные автомобили с аналитикой цен"
    static let verified = "Проверено CoolAV"
    static let liveMarket = "LIVE рынок РБ"
    static let ticker: [String] = [
        "Geely Monjaro 2023: -$2,700 ниже рынка (Минск)",
        "Средний чек в августе: $24,800",
        "Tesla Model 3 LR: без утильсбора и налога на роскошь",
        "Проверено по базам ГАИ за сегодня: +1,420 авто",
        "Свежий пригон из Мюнхена: BMW 520d G30 M-Sport",
        "Средний срок продажи проверенных авто: 12 дней",
        "Li Auto L7 Pro: выгода до $3,700 при покупке онлайн",
        "Volkswagen Tiguan II: ТОП-1 по ликвидности в Беларуси"
    ]
}
