import Foundation

enum ModelInsight {
    struct Insight: Equatable, Sendable, Identifiable, Hashable {
        var id: String
        var make: String
        var model: String
        var year: Int
        var avgPriceUSD: Int
        var priceRange: String
        var liquidityDays: Int
        var depreciationPerYear: Double
        var fuelType: String
        var fuelConsumption: String
        var monthlyUSD: Int
        var powerHp: Int
        var acceleration0100: Double
        var trunkVolumeL: Int
        var parts: Double
        var comfort: Double
        var reliability: Double
        var overall: Double
        var tag: String
        var pros: [String]
        var cons: [String]
        var idealFor: String
        var weakSpots: String
    }

    static let catalog: [Insight] = [
        Insight(
            id: "geely-monjaro",
            make: "Geely",
            model: "Monjaro 2.0T 4WD (Exclusive)",
            year: 2023,
            avgPriceUSD: 36_500,
            priceRange: "$34,200 – $38,900",
            liquidityDays: 13,
            depreciationPerYear: 5.8,
            fuelType: "Бензин 2.0T (238 л.с.)",
            fuelConsumption: "9.4 л/100км",
            monthlyUSD: 190,
            powerHp: 238,
            acceleration0100: 7.7,
            trunkVolumeL: 562,
            parts: 9.8,
            comfort: 9.2,
            reliability: 9.1,
            overall: 9.4,
            tag: "Топ-ликвидность в РБ",
            pros: [
                "Официальная дилерская гарантия и изобилие запчастей в РБ",
                "Проверенная платформа CMA (Volvo) и классический 8-ст автомат Aisin",
                "Богатое оснащение (3 экрана, вентиляция, панорама, ассистенты)",
                "Минимальная потеря стоимости на вторичном рынке Беларуси"
            ],
            cons: [
                "Расход топлива в городе до 11-13 л на 100 км",
                "Специфическая локализация некоторых мультимедиа функций"
            ],
            idealFor: "Семейных людей и практичных покупателей, которым нужен свежий надежный кроссовер на каждый день без головной боли по запчастям и с быстрой продажей.",
            weakSpots: "Калибровка датчиков адаптивного круиза, состояние ЛКП на капоте без бронепленки."
        ),
        Insight(
            id: "bmw-5-g30",
            make: "BMW",
            model: "5-Series G30 (520d xDrive M-Sport)",
            year: 2020,
            avgPriceUSD: 32_800,
            priceRange: "$29,900 – $36,500",
            liquidityDays: 19,
            depreciationPerYear: 7.5,
            fuelType: "Дизель 2.0d (190 л.с.)",
            fuelConsumption: "5.9 л/100км",
            monthlyUSD: 230,
            powerHp: 190,
            acceleration0100: 7.5,
            trunkVolumeL: 530,
            parts: 8.5,
            comfort: 9.6,
            reliability: 8.8,
            overall: 9.2,
            tag: "Премиум драйв и комфорт",
            pros: [
                "Эталонная управляемость, идеальная шумоизоляция и статус бренда",
                "Легендарный экономичный и тяговитый дизель B47",
                "Премиальные материалы отделки и надежный автомат ZF 8HP",
                "Очень высокая дальнобойность (более 1000 км на одном баке)"
            ],
            cons: [
                "Более дорогое обслуживание оригинальными расходниками",
                "Высокий риск скрученного пробега на европейских пригнанных авто"
            ],
            idealFor: "Ценителей немецкой управляемости, статуса и комфорта в дальних трассовых поездках, готовых регулярно и качественно обслуживать авто.",
            weakSpots: "Демпфер коленвала, клапан EGR и теплообменник (проверка по отзывной кампании), состояние вихревых заслонок."
        ),
        Insight(
            id: "vw-tiguan",
            make: "Volkswagen",
            model: "Tiguan II (2.0 TSI 4Motion Highline)",
            year: 2021,
            avgPriceUSD: 27_900,
            priceRange: "$25,500 – $30,800",
            liquidityDays: 12,
            depreciationPerYear: 5.4,
            fuelType: "Бензин 2.0 TSI (180 л.с.)",
            fuelConsumption: "8.4 л/100км",
            monthlyUSD: 175,
            powerHp: 180,
            acceleration0100: 7.7,
            trunkVolumeL: 615,
            parts: 9.5,
            comfort: 8.7,
            reliability: 9.0,
            overall: 9.1,
            tag: "Народный бестселлер",
            pros: [
                "Рекордная ликвидность на CoolAV — продаётся буквально за 1–2 недели",
                "Огромный трансформируемый багажник и образцовая эргономика салона",
                "Надежная связка мотора EA888 Gen3b и «мокрого» робота DSG DQ500",
                "Любой автосервис в Беларуси знает эту машину наизусть"
            ],
            cons: [
                "Строгий консервативный дизайн интерьера",
                "Жестковатая подвеска на 19-дюймовых колесах"
            ],
            idealFor: "Универсального семейного использования город/дача/путешествия с максимальной сохраняемостью бюджета и минимальными тратами.",
            weakSpots: "Помпа охлаждения, сайлентблоки передних рычагов, масло в муфте Haldex (требует замены каждые 40 тыс. км)."
        ),
        Insight(
            id: "tesla-model-3",
            make: "Tesla",
            model: "Model 3 Long Range Dual Motor",
            year: 2022,
            avgPriceUSD: 34_200,
            priceRange: "$31,500 – $37,800",
            liquidityDays: 22,
            depreciationPerYear: 8.2,
            fuelType: "Электро (440 л.с., 78 кВт·ч)",
            fuelConsumption: "17 кВт·ч/100км",
            monthlyUSD: 65,
            powerHp: 440,
            acceleration0100: 4.4,
            trunkVolumeL: 561,
            parts: 7.2,
            comfort: 8.6,
            reliability: 8.9,
            overall: 8.9,
            tag: "Сверхдинамика и экономия",
            pros: [
                "Ураганный разгон (0–100 за 4.4 с) и фантастическая отзывчивость",
                "Копеечная стоимость «заправки» в РБ (особенно по ночному тарифу)",
                "Отсутствие трат на замену масла, ремней, свечей и выхлопа",
                "Постоянные обновления по воздуху и умный автопилот"
            ],
            cons: [
                "Зависимость от зарядной инфраструктуры при поездках по регионам",
                "Жесткая подвеска и простоватые материалы салона по сравнению с премиумом"
            ],
            idealFor: "Горожан с возможностью зарядки дома или в офисе, фанатов технологий и тех, кто хочет динамику без налога на роскошь и трат на бензин.",
            weakSpots: "Рычаги передней подвески (скрип шаровых), остаточная деградация батареи (проверять через сервисное меню SOH)."
        ),
        Insight(
            id: "mercedes-e-w213",
            make: "Mercedes-Benz",
            model: "E-Class W213 (E220d 4Matic AMG Line)",
            year: 2020,
            avgPriceUSD: 36_900,
            priceRange: "$33,800 – $41,000",
            liquidityDays: 24,
            depreciationPerYear: 7.9,
            fuelType: "Дизель 2.0d (194 л.с.)",
            fuelConsumption: "6.2 л/100км",
            monthlyUSD: 250,
            powerHp: 194,
            acceleration0100: 7.5,
            trunkVolumeL: 540,
            parts: 8.2,
            comfort: 9.8,
            reliability: 8.7,
            overall: 9.1,
            tag: "Бизнес-класс и статус",
            pros: [
                "Безупречный комфорт подвески, тишина и премиальная эстетика интерьера",
                "Сверхнадежный дизельный мотор OM654 и 9-ступенчатый 9G-Tronic",
                "Высокая остаточная ценность у ценителей марки",
                "Великолепная оптика Multibeam LED"
            ],
            cons: [
                "Дорогая кузовщина и электронные блоки при ремонте",
                "Внушительные затраты на комплексное ТО в клубных сервисах"
            ],
            idealFor: "Предпринимателей и руководителей, которым важен строгий представительский статус, максимальная плавность хода и расслабляющий комфорт.",
            weakSpots: "Блок управления AdBlue/SCR, подушки пневмоподвески (если установлена Air Body Control), датчики парктроников."
        ),
        Insight(
            id: "audi-a6-c8",
            make: "Audi",
            model: "A6 C8 (40 TDI Quattro S-Line)",
            year: 2021,
            avgPriceUSD: 38_400,
            priceRange: "$35,000 – $43,500",
            liquidityDays: 21,
            depreciationPerYear: 7.2,
            fuelType: "Дизель 2.0 TDI (204 л.с.)",
            fuelConsumption: "6.1 л/100км",
            monthlyUSD: 240,
            powerHp: 204,
            acceleration0100: 7.6,
            trunkVolumeL: 530,
            parts: 8.4,
            comfort: 9.5,
            reliability: 8.9,
            overall: 9.2,
            tag: "Технологии и Quattro",
            pros: [
                "Фирменный полный привод Quattro ultra и идеальная курсовая устойчивость зимой",
                "Футуристичный салон с двойным сенсорным экраном MMI Touch Response",
                "Мягкий гибрид MHEV (12V) для снижения расхода топлива в пробках",
                "Отличная шумоизоляция с двойными боковыми стеклами"
            ],
            cons: [
                "Сложная многорычажная алюминиевая подвеска",
                "Маркие сенсорные панели в салоне"
            ],
            idealFor: "Любителей хай-тек интерьеров и уверенного зимнего вождения по белорусским трассам в любую погоду.",
            weakSpots: "Стартер-генератор RSG в системе MHEV, состояние сцеплений в роботе S-Tronic DL382."
        ),
        Insight(
            id: "toyota-rav4",
            make: "Toyota",
            model: "RAV4 XA50 (2.5 Hybrid AWD Prestige)",
            year: 2021,
            avgPriceUSD: 33_500,
            priceRange: "$31,000 – $36,800",
            liquidityDays: 11,
            depreciationPerYear: 4.6,
            fuelType: "Гибрид 2.5 (222 л.с.)",
            fuelConsumption: "5.2 л/100км",
            monthlyUSD: 140,
            powerHp: 222,
            acceleration0100: 8.1,
            trunkVolumeL: 580,
            parts: 9.4,
            comfort: 8.5,
            reliability: 9.7,
            overall: 9.3,
            tag: "Железобетонная надежность",
            pros: [
                "Непревзойденная надежность гибридной силовой установки e-CVT",
                "Минимальное падение стоимости в Беларуси (лучшая ликвидность в классе)",
                "Смешной расход топлива 5–6 литров бензина в городском цикле",
                "Простая и неубиваемая ходовая часть"
            ],
            cons: [
                "Посредственная шумоизоляция колесных арок (требует доработки)",
                "Простые отделочные материалы в сравнении с европейцами"
            ],
            idealFor: "Покупателей, для которых главное — сел и поехал на 5 лет без единой поломки, с минимальными затратами на содержание и продажей за 3 дня.",
            weakSpots: "Кабель высоковольтного привода задней оси e-Four (проверка на коррозию), рулевой шлейф."
        ),
        Insight(
            id: "li-auto-l7",
            make: "Li Auto",
            model: "L7 Pro (Последовательный гибрид 4WD)",
            year: 2023,
            avgPriceUSD: 44_900,
            priceRange: "$41,500 – $48,900",
            liquidityDays: 16,
            depreciationPerYear: 9.1,
            fuelType: "REEV гибрид (449 л.с., 1.5T + 42.8 кВт·ч)",
            fuelConsumption: "7.5 л/100км (или 0 на батарее)",
            monthlyUSD: 110,
            powerHp: 449,
            acceleration0100: 5.3,
            trunkVolumeL: 600,
            parts: 7.9,
            comfort: 9.7,
            reliability: 8.8,
            overall: 9.3,
            tag: "Премиум будущего",
            pros: [
                "Королевский простор на втором ряду и пневмоподвеска с регулировкой клиренса",
                "170 км чисто на электричестве плюс генератор на бензине (запас хода 1100 км)",
                "Фантастическая мультимедиа и системы помощи водителю Lidar",
                "Быстрый разгон 5.3 с до сотни при весе 2.4 тонны"
            ],
            cons: [
                "Необходимость мастер-аккаунта и русификации прошивки",
                "Дорогая кузовщина при ДТП и ожидание редких деталей"
            ],
            idealFor: "Семьи, которая хочет максимальный комфорт премиального уровня по цене обычного паркетника, с гибридной независимостью от розеток.",
            weakSpots: "Пневмобаллоны в сильные морозы, состояние 12V аккумулятора, привязка китайского телефонного номера в приложении."
        )
    ]

    private static let fallback = Insight(
        id: "fallback",
        make: "",
        model: "",
        year: 0,
        avgPriceUSD: 0,
        priceRange: "—",
        liquidityDays: 18,
        depreciationPerYear: 7,
        fuelType: "—",
        fuelConsumption: "—",
        monthlyUSD: 180,
        powerHp: 0,
        acceleration0100: 0,
        trunkVolumeL: 0,
        parts: 8.0,
        comfort: 8.0,
        reliability: 8.0,
        overall: 8.5,
        tag: "Рынок РБ",
        pros: [],
        cons: [],
        idealFor: "",
        weakSpots: ""
    )

    static func lookup(make: String, model: String = "") -> Insight {
        let needle = model.lowercased()
        if !needle.isEmpty,
           let hit = catalog.first(where: { $0.make == make && $0.model.lowercased().contains(needle) }) {
            return hit
        }
        if let hit = catalog.first(where: { $0.make == make }) {
            return hit
        }
        return fallback
    }

    static var makes: [String] {
        var seen = Set<String>()
        return catalog.map(\.make).filter { seen.insert($0).inserted }
    }
}
