import Foundation

struct VehicleCatalog: Codable, Sendable {
    var makes: [CatalogMake]

    static func load(from url: URL) throws -> VehicleCatalog {
        try JSONDecoder().decode(VehicleCatalog.self, from: Data(contentsOf: url))
    }

    static let bundled: VehicleCatalog = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let catalog = try? load(from: url) else {
            return VehicleCatalog(makes: [])
        }
        return catalog
    }()
}

struct CatalogMake: Codable, Sendable {
    var name: String
    var models: [CatalogModel]
}

struct CatalogModel: Codable, Sendable {
    var name: String
    var generations: [String]
}

enum FilterCatalog {
    static func makes(in listings: [Listing]) -> [String] {
        unique(\.make, in: listings)
    }

    static func models(in listings: [Listing], make: String?) -> [String] {
        unique(\.model, in: scoped(listings, make: make, model: nil))
    }

    static func generations(in listings: [Listing], make: String?, model: String?) -> [String] {
        Array(
            Set(
                scoped(listings, make: make, model: model)
                    .compactMap(\.generation)
            )
        ).sorted()
    }

    static func bodies(in listings: [Listing]) -> [String] {
        unique(\.body, in: listings)
    }

    static func cities(in listings: [Listing]) -> [String] {
        unique(\.city, in: listings)
    }

    static func regions(in listings: [Listing]) -> [String] {
        unique(\.region, in: listings)
    }

    static func fuels(in listings: [Listing]) -> [String] {
        unique(\.fuel, in: listings, fallback: ["бензин", "дизель", "гибрид", "электро"])
    }

    static func transmissions(in listings: [Listing]) -> [String] {
        unique(\.transmission, in: listings, fallback: ["автомат", "механика", "робот", "вариатор"])
    }

    static func drivetrains(in listings: [Listing]) -> [String] {
        unique(\.drivetrain, in: listings, fallback: ["передний", "полный", "задний"])
    }

    static let defaultMakes = [
        "Audi", "BMW", "Geely", "Hyundai", "Lada", "Mercedes-Benz", "Renault", "Skoda", "Toyota", "Volkswagen"
    ]

    static let defaultBodies = ["седан", "универсал", "хэтчбек", "кроссовер", "минивэн", "купе"]

    static let defaultCities = ["Минск", "Брест", "Витебск", "Гомель", "Гродно", "Могилёв"]

    static let defaultRegions = ["Минская", "Брестская", "Витебская", "Гомельская", "Гродненская", "Могилёвская"]

    static func makesForPost(in listings: [Listing], catalog: VehicleCatalog = .bundled) -> [String] {
        Array(Set(makes(in: listings) + defaultMakes + catalog.makes.map(\.name))).sorted()
    }

    static func modelsForPost(in listings: [Listing], make: String, catalog: VehicleCatalog = .bundled) -> [String] {
        let fromListings = models(in: listings, make: make)
        let fromCatalog = catalog.makes.first { $0.name == make }?.models.map(\.name) ?? []
        return Array(Set(fromListings + fromCatalog)).sorted()
    }

    static func generationsForPost(
        in listings: [Listing],
        make: String,
        model: String,
        catalog: VehicleCatalog = .bundled
    ) -> [String] {
        let fromListings = generations(in: listings, make: make, model: model)
        let fromCatalog = catalog.makes.first { $0.name == make }?
            .models.first { $0.name == model }?
            .generations ?? []
        return Array(Set(fromListings + fromCatalog)).sorted()
    }

    static func bodiesForPost(in listings: [Listing]) -> [String] {
        Array(Set(bodies(in: listings) + defaultBodies)).sorted()
    }

    static func citiesForPost(in listings: [Listing]) -> [String] {
        Array(Set(cities(in: listings) + defaultCities)).sorted()
    }

    private static func scoped(_ listings: [Listing], make: String?, model: String?) -> [Listing] {
        listings.filter { listing in
            if let make, listing.make != make { return false }
            if let model, listing.model != model { return false }
            return true
        }
    }

    private static func unique(_ key: KeyPath<Listing, String>, in listings: [Listing], fallback: [String] = []) -> [String] {
        let values = Array(Set(listings.map { $0[keyPath: key] } + fallback))
        return values.filter { !$0.isEmpty }.sorted()
    }
}
