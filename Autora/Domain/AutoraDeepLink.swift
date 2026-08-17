import Foundation

enum AutoraDeepLink {
    static func listingID(from url: URL) -> String? {
        guard url.scheme == "autora", url.host == "listing" else { return nil }
        let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return id.isEmpty ? nil : id
    }
}
