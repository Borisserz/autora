import Foundation

enum ChatDraft {
    static func normalized(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func priceOffer(make: String, model: String, targetUSD: Int) -> String {
        "Здравствуйте! Готов купить \(make) \(model) за $\(targetUSD). Когда можно посмотреть?"
    }
}
