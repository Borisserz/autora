import Foundation

struct ListingDraft: Equatable, Codable, Sendable {
    var make: String = ""
    var model: String = ""
    var generation: String = ""
    var year: Int = 2018
    var priceBYN: Int = 0
    var mileageKm: Int = 0
    var body: String = "седан"
    var fuel: String = "бензин"
    var transmission: String = "автомат"
    var drivetrain: String = "передний"
    var engineLiters: Double = 1.6
    var powerHp: Int = 110
    var city: String = "Минск"
    var region: String = "Минская"
    var vin: String = ""
    var description: String = ""
    var photoURLs: [String] = []
    var bargaining: Bool = true
    var exchange: Bool = false
    var wheel: WheelSide = .left
    var registered: Bool = true
    var customsCleared: Bool = true
    var condition: ListingCondition = .used
    var equipment: [String] = []
    var valuationCondition: MarketValuation.Condition = .good

    static var sample: ListingDraft {
        var draft = ListingDraft()
        draft.make = "Volkswagen"
        draft.model = "Passat"
        draft.year = 2018
        draft.priceBYN = 14500
        draft.mileageKm = 120_000
        draft.description = "Продаю свой автомобиль. Один хозяин."
        return draft
    }

    static func normalizedVIN(_ raw: String) -> String {
        raw.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    static func from(_ listing: Listing) -> ListingDraft {
        var draft = ListingDraft()
        draft.make = listing.make
        draft.model = listing.model
        draft.generation = listing.generation ?? ""
        draft.year = listing.year
        draft.priceBYN = listing.priceBYN
        draft.mileageKm = listing.mileageKm
        draft.body = listing.body
        draft.fuel = listing.fuel
        draft.transmission = listing.transmission
        draft.drivetrain = listing.drivetrain
        draft.engineLiters = listing.engineLiters
        draft.powerHp = listing.powerHp
        draft.city = listing.city
        draft.region = listing.region
        draft.vin = listing.vin ?? ""
        draft.description = listing.description
        draft.photoURLs = listing.photoURLs
        draft.bargaining = listing.bargaining
        draft.exchange = listing.exchange
        draft.wheel = listing.wheel
        draft.registered = listing.registered
        draft.customsCleared = listing.customsCleared
        draft.condition = listing.condition
        draft.equipment = listing.equipment ?? []
        return draft
    }

    func suggestedQuote(usdBYN: Double, nowYear: Int = 2026) -> MarketValuation.Quote {
        MarketValuation.quote(
            make: make,
            year: year,
            mileageKm: mileageKm,
            condition: valuationCondition,
            usdBYN: usdBYN,
            nowYear: nowYear
        )
    }

    mutating func applySuggestedPrice(usdBYN: Double, nowYear: Int = 2026) {
        priceBYN = suggestedQuote(usdBYN: usdBYN, nowYear: nowYear).byn
    }

    func canLeave(step: Int) -> Bool {
        switch step {
        case 0: !photoURLs.isEmpty
        case 1:
            Self.normalizedVIN(vin).isEmpty || Self.normalizedVIN(vin).count == 17
        case 2:
            !make.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3: priceBYN > 0
        default: true
        }
    }

    func leaveError(for step: Int) -> AppError? {
        guard !canLeave(step: step) else { return nil }
        switch step {
        case 0: return .needPhoto
        case 1: return .needVIN
        case 2: return .needMake
        case 3: return .needPrice
        default: return nil
        }
    }

    func apply(onto listing: Listing, seller: UserProfile, now: TimeInterval) throws -> Listing {
        var next = try makeListing(id: listing.id, seller: seller, now: now)
        next.views = listing.views
        next.favoritesCount = listing.favoritesCount
        next.phoneReveals = listing.phoneReveals
        next.createdAt = listing.createdAt
        next.bumpedAt = listing.bumpedAt
        next.isDemo = listing.isDemo
        next.isTop = listing.isTop
        next.status = listing.status
        next.sellerListingCount = listing.sellerListingCount
        return next
    }

    func makeListing(id: String, seller: UserProfile, now: TimeInterval) throws -> Listing {
        guard !photoURLs.isEmpty else { throw AppError.needPhoto }
        let make = make.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !make.isEmpty, !model.isEmpty else { throw AppError.needMake }
        guard priceBYN > 0 else { throw AppError.needPrice }
        let vinNormalized = Self.normalizedVIN(vin)
        if !vinNormalized.isEmpty, vinNormalized.count != 17 { throw AppError.needVIN }
        return Listing(
            id: id,
            sellerId: seller.id,
            sellerName: seller.name,
            sellerPhone: seller.phone,
            sellerListingCount: 1,
            make: make,
            model: model,
            generation: generation.isEmpty ? nil : generation,
            year: year,
            priceBYN: priceBYN,
            mileageKm: mileageKm,
            body: body,
            fuel: fuel,
            transmission: transmission,
            drivetrain: drivetrain,
            engineLiters: engineLiters,
            powerHp: powerHp,
            city: city,
            region: region,
            condition: condition,
            registered: registered,
            customsCleared: customsCleared,
            wheel: wheel,
            hasPhotos: true,
            bargaining: bargaining,
            exchange: exchange,
            forParts: false,
            damaged: false,
            vin: vinNormalized.isEmpty ? nil : vinNormalized,
            isTop: false,
            isDemo: false,
            status: .active,
            photoURLs: photoURLs,
            description: description,
            views: 0,
            favoritesCount: 0,
            phoneReveals: 0,
            bumpedAt: now,
            createdAt: now,
            equipment: equipment.isEmpty ? nil : equipment
        )
    }
}
