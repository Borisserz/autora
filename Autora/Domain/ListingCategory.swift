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
    static let heroBadge = "Легковые в Беларуси"
    static let heroTitle = "Покупка и продажа. Цена в данных — Br."
    static let heroSubtitle = "Сравнивайте лоты, держите цель в гараже, проверяйте VIN демо-сверкой CoolAV."
    static let searchPlaceholder = "Марка, модель, кузов, город или опции"
    static let catalogEyebrow = "Каталог CoolAV"
    static let catalogTitle = "Объявления с ценой в Br и курсом $ на экране"
    static let verified = "ТОП CoolAV"
    static let liveMarket = "CoolAV"
    static let vinLead = "Демо-сверка CoolAV. Не база ГАИ и не отчёт чужого сайта."
    static let ticker: [String] = [
        "Цена в данных — Br. На экране $ крупно, Br рядом.",
        "Гараж: избранное, цена к цели, автопарк и поиски.",
        "Сравнение — два лота: цена, пробег, срок продажи.",
        "VIN в CoolAV — демо-сверка, не база ГАИ.",
        "Подача: свои фото и полный телефон в профиле.",
        "Скрытый продавец пропадает из ленты, не из каталога продавца."
    ]
}
