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

    func suggestedQuote(usdBYN: Double, nowYear: Int = 2026) -> MarketValuation.Quote {
        MarketValuation.quote(
            make: make,
            year: year,
            mileageKm: mileageKm,
            condition: .good,
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
        case 2: return .needMake
        case 3: return .needPrice
        default: return nil
        }
    }

    func makeListing(id: String, seller: UserProfile, now: TimeInterval) throws -> Listing {
        guard !photoURLs.isEmpty else { throw AppError.needPhoto }
        let make = make.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !make.isEmpty, !model.isEmpty else { throw AppError.needMake }
        guard priceBYN > 0 else { throw AppError.needPrice }
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
            vin: vin.isEmpty ? nil : vin,
            isTop: false,
            isDemo: false,
            status: .active,
            photoURLs: photoURLs,
            description: description,
            views: 0,
            favoritesCount: 0,
            phoneReveals: 0,
            bumpedAt: now,
            createdAt: now
        )
    }
}
