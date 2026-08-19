import Foundation

enum PhotoGallery {
    static let captions = [
        "Экстерьер",
        "Интерьер и руль",
        "Второй ряд",
        "Диски и оптика"
    ]

    static func caption(index: Int, count: Int) -> String {
        if captions.indices.contains(index) {
            return captions[index]
        }
        return "Фото \(index + 1)"
    }
}
