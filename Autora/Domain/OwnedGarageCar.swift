import Foundation

struct OwnedGarageCar: Identifiable, Codable, Equatable, Sendable, Hashable {
    var id: String
    var make: String
    var model: String
    var year: Int
    var currentValueUSD: Int
    var currentValueBYN: Int
    var monthlyChangeUSD: Int
    var mileageKm: Int
    var nextMotDate: String
    var nextInsuranceDate: String
    var nextOilServiceKm: Int
    var city: String
    var engine: String
    var photoURL: String?

    var title: String { "\(make) \(model)" }

    static let demoFleet: [OwnedGarageCar] = [
        OwnedGarageCar(
            id: "gar-1",
            make: "Geely",
            model: "Coolray 1.5T Flagship",
            year: 2022,
            currentValueUSD: 21_800,
            currentValueBYN: 71_500,
            monthlyChangeUSD: 420,
            mileageKm: 34_000,
            nextMotDate: "15.10.2026",
            nextInsuranceDate: "28.09.2026",
            nextOilServiceKm: 40_000,
            city: "Минск",
            engine: "1.5T Бензин (177 л.с.)",
            photoURL: nil
        ),
        OwnedGarageCar(
            id: "gar-2",
            make: "BMW",
            model: "3-Series G20 320d xDrive",
            year: 2020,
            currentValueUSD: 28_400,
            currentValueBYN: 93_150,
            monthlyChangeUSD: -180,
            mileageKm: 78_000,
            nextMotDate: "04.12.2026",
            nextInsuranceDate: "15.11.2026",
            nextOilServiceKm: 85_000,
            city: "Минск",
            engine: "2.0d Дизель (190 л.с.)",
            photoURL: nil
        )
    ]
}
