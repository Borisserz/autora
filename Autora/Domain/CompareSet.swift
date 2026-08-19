import Foundation

enum CompareSet {
    static let limit = 2

    static func toggling(_ id: String, in ids: [String]) -> [String] {
        if let idx = ids.firstIndex(of: id) {
            var copy = ids
            copy.remove(at: idx)
            return copy
        }
        guard ids.count < limit else { return ids }
        return ids + [id]
    }

    static func setting(_ id: String, at index: Int, in ids: [String]) -> [String] {
        guard index >= 0, index < limit else { return ids }
        var slots = ids.filter { $0 != id }
        if index < slots.count {
            slots[index] = id
        } else {
            slots.append(id)
        }
        return Array(slots.prefix(limit))
    }
}
