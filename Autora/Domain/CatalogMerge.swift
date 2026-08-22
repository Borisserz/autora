import Foundation

enum CatalogMerge {
    static func listings(seed: [Listing], mine: [Listing], remote: [Listing] = []) -> [Listing] {
        let mineIDs = Set(mine.map(\.id))
        let remoteUnique = remote.filter { !mineIDs.contains($0.id) }
        let taken = mineIDs.union(Set(remoteUnique.map(\.id)))
        let rest = seed.filter { !taken.contains($0.id) }
        return mine + remoteUnique + rest
    }

    static func chats(seed: [ChatThread], live: [ChatThread]) -> [ChatThread] {
        var byID = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
        for thread in live {
            byID[thread.id] = thread
        }
        let seedIDs = Set(seed.map(\.id))
        let extras = live.filter { !seedIDs.contains($0.id) }
        let rest = seed.compactMap { byID[$0.id] }
        return extras + rest
    }
}
