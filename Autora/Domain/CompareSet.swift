import Foundation

enum CompareSet {
    static let limit = 3

    static func toggling(_ id: String, in ids: [String]) -> [String] {
        if let idx = ids.firstIndex(of: id) {
            var copy = ids
            copy.remove(at: idx)
            return copy
        }
        guard ids.count < limit else { return ids }
        return ids + [id]
    }
}
