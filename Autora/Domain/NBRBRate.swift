import Foundation

enum NBRBRate {
    static func parse(_ data: Data) throws -> Double {
        let object = try JSONSerialization.jsonObject(with: data)
        let dict: [String: Any]
        if let one = object as? [String: Any] {
            dict = one
        } else if let list = object as? [[String: Any]], let first = list.first {
            dict = first
        } else {
            throw NBRBRateError.invalidJSON
        }
        let rate = number(dict, "Cur_OfficialRate")
        let scale = number(dict, "Cur_Scale") ?? 1
        guard let rate, rate > 0, scale > 0 else { throw NBRBRateError.invalidJSON }
        return rate / scale
    }

    private static func number(_ dict: [String: Any], _ key: String) -> Double? {
        if let value = dict[key] as? NSNumber { return value.doubleValue }
        if let value = dict[key] as? Double { return value }
        return nil
    }

    static func pick(fetched: Double?, cached: Double?, seed: Double) -> FXRate {
        if let fetched, fetched > 0 {
            return FXRate(usdBYN: fetched, source: .nbrb)
        }
        if let cached, cached > 0 {
            return FXRate(usdBYN: cached, source: .cache)
        }
        return FXRate(usdBYN: seed, source: .seed)
    }
}

enum NBRBRateError: Error {
    case invalidJSON
}

enum NBRBClient {
    static let usdURL = URL(string: "https://api.nbrb.by/exrates/rates/431")!

    static func fetchUSDBYN(session: URLSession = .shared) async throws -> Double {
        let (data, response) = try await session.data(from: usdURL)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw NBRBRateError.invalidJSON
        }
        return try NBRBRate.parse(data)
    }
}
