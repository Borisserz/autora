import SwiftUI
import UIKit

enum AutoraTheme {
    static let canvas = Color(
        light: Color(red: 1, green: 1, blue: 1),
        dark: Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255)
    )
    static let surface = Color(
        light: Color(red: 244 / 255, green: 243 / 255, blue: 243 / 255),
        dark: Color(red: 20 / 255, green: 20 / 255, blue: 22 / 255)
    )
    static let ink = Color(
        light: Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255),
        dark: Color(red: 1, green: 1, blue: 1)
    )
    static let muted = Color(
        light: Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255),
        dark: Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)
    )
    static let accent = ink
    static let price = ink
    static let emerald = Color(red: 16 / 255, green: 185 / 255, blue: 129 / 255)
    static let garageBlue = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)
    static let bargainRed = Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)
    static let amber = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
    static let europeGreen = Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255)
    static let premiumPurple = Color(red: 88 / 255, green: 28 / 255, blue: 135 / 255)
    static let badgeTop = bargainRed
    static let danger = Color(
        light: Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255),
        dark: Color(red: 248 / 255, green: 113 / 255, blue: 113 / 255)
    )
    static let hairline = Color(
        light: Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255).opacity(0.08),
        dark: Color.white.opacity(0.12)
    )
    static let glass = Color.black.opacity(0.65)
    static let detailCanvas = Color(red: 20 / 255, green: 20 / 255, blue: 22 / 255)
    static let photoRadius: CGFloat = 24
    static let chipRadius: CGFloat = 14
    static let specRadius: CGFloat = 12
    static let cardPhotoHeight: CGFloat = 220
    static let detailPhotoHeight: CGFloat = 280
    static let pageGutter: CGFloat = 16
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
            }
        )
    }
}
