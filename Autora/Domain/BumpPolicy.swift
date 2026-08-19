import Foundation

struct BumpPolicy: Equatable, Sendable {
    static let interval: TimeInterval = 20 * 60 * 60
    static let lifetime: TimeInterval = 30 * 24 * 60 * 60

    static func canBump(lastBumped: TimeInterval, now: TimeInterval) -> Bool {
        now - lastBumped >= interval
    }

    static func nextBumpDate(lastBumped: TimeInterval) -> Date {
        Date(timeIntervalSince1970: lastBumped + interval)
    }

    static func isExpired(bumpedAt: TimeInterval, now: TimeInterval, isDemo: Bool = false) -> Bool {
        if isDemo { return false }
        return now - bumpedAt >= lifetime
    }

    static func hoursUntilBump(lastBumped: TimeInterval, now: TimeInterval) -> Int {
        let remaining = interval - (now - lastBumped)
        if remaining <= 0 { return 0 }
        return Int(ceil(remaining / 3600))
    }
}
