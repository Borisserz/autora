import Foundation

enum PriceConverter {
    static func usd(fromBYN byn: Int, rate: Double) -> Double {
        guard rate > 0 else { return 0 }
        return (Double(byn) / rate * 100).rounded() / 100
    }

    static func byn(fromUSD usd: Double, rate: Double) -> Int {
        guard rate > 0 else { return 0 }
        return Int((usd * rate).rounded())
    }

    static func filterUSD(fromBYN byn: Int, rate: Double) -> Int {
        Int(usd(fromBYN: byn, rate: rate).rounded())
    }

    static func formatBYN(_ value: Int) -> String {
        let formatted = value.formatted(.number.grouping(.automatic))
        return "\(formatted) Br"
    }

    static func formatUSD(_ value: Double) -> String {
        let n = Int(value.rounded())
        return "$\(n.formatted(.number.grouping(.automatic)))"
    }

    static func formatUSDReference(_ value: Double) -> String {
        "\(formatUSD(value)) справочно"
    }
}
