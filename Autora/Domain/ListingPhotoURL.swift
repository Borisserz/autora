import Foundation

enum ListingPhotoURL {
    static let siteBase = "https://coolav.by"

    static func resolve(_ raw: String, siteBase: String = siteBase) -> URL? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if value.hasPrefix("http://") || value.hasPrefix("https://") || value.hasPrefix("file://") {
            return URL(string: value)
        }
        if value.hasPrefix("/") {
            return URL(string: siteBase + value)
        }
        return URL(string: value)
    }

    static func normalized(_ raw: String, siteBase: String = siteBase) -> String {
        resolve(raw, siteBase: siteBase)?.absoluteString ?? raw
    }
}
