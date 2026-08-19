import Foundation

enum PhoneLink {
    static func telURL(_ phone: String) -> URL? {
        let allowed = phone.filter { $0.isNumber || $0 == "+" }
        guard !allowed.isEmpty else { return nil }
        return URL(string: "tel:\(allowed)")
    }
}

enum BelarusPhone {
    static func display(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return "" }
        var normalized = digits
        if normalized.hasPrefix("375") {
            normalized.removeFirst(3)
        } else if normalized.hasPrefix("80") {
            normalized.removeFirst(2)
        }
        if normalized.count > 9 {
            normalized = String(normalized.prefix(9))
        }
        let chars = Array(normalized)
        func part(_ start: Int, _ end: Int) -> String {
            guard start < chars.count else { return "" }
            return String(chars[start..<min(end, chars.count)])
        }
        let part1 = part(0, 2)
        let part2 = part(2, 5)
        let part3 = part(5, 7)
        let part4 = part(7, 9)
        var result = "+375"
        if !part1.isEmpty { result += " (\(part1)" }
        if part1.count == 2 { result += ")" }
        if !part2.isEmpty { result += " \(part2)" }
        if !part3.isEmpty { result += "-\(part3)" }
        if !part4.isEmpty { result += "-\(part4)" }
        return result
    }

    static func e164(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return "" }
        var normalized = digits
        if normalized.hasPrefix("375") {
            normalized.removeFirst(3)
        } else if normalized.hasPrefix("80") {
            normalized.removeFirst(2)
        }
        let local = String(normalized.prefix(9))
        guard !local.isEmpty else { return "" }
        return "+375" + local
    }
}
