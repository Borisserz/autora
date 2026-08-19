import Foundation

enum PhotoGallery {
    static func caption(index: Int, count: Int) -> String {
        "Фото \(index + 1) из \(count)"
    }
}
