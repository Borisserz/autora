import Foundation

struct VinReport: Equatable, Sendable {
    struct MileageEvent: Equatable, Sendable, Identifiable {
        var id: String { "\(date)-\(km)" }
        var date: String
        var title: String
        var km: Int
    }

    struct RegistryEvent: Equatable, Sendable, Identifiable {
        var id: String { title }
        var title: String
        var detail: String
    }

    struct Sample: Equatable, Sendable, Identifiable {
        var id: String { vin }
        var label: String
        var vin: String
    }

    var vin: String
    var wantedOK: Bool
    var liensOK: Bool
    var accidentsOK: Bool
    var ownersInBY: Int
    var safetyScore: Double
    var mileage: [MileageEvent]
    var registry: [RegistryEvent]

    static let samples: [Sample] = [
        Sample(label: "Geely Monjaro (2023)", vin: "X7LLG1234PA987654"),
        Sample(label: "BMW 520d G30 (2020)", vin: "WBA5A51000G123456"),
        Sample(label: "VW Tiguan (2021)", vin: "WVWZZZ5NZMW123456")
    ]

    static func demo(vin: String) -> VinReport {
        let cleaned = vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return VinReport(
            vin: cleaned,
            wantedOK: true,
            liensOK: true,
            accidentsOK: true,
            ownersInBY: 1,
            safetyScore: 9.8,
            mileage: [
                MileageEvent(date: "14.04.2025", title: "Официальное ТО дилера (Минск)", km: 28_140),
                MileageEvent(date: "20.03.2024", title: "Прохождение ТО (Белтехосмотр)", km: 14_890),
                MileageEvent(date: "10.05.2023", title: "Покупка новым в автосалоне", km: 15)
            ],
            registry: [
                RegistryEvent(title: "Постановка на постоянный учёт (Минск)", detail: "Физ. лицо • Май 2023 — настоящее время"),
                RegistryEvent(title: "Таможенное оформление и выдача ЭПТС", detail: "Утильсбор уплачен в полном объёме")
            ]
        )
    }
}
