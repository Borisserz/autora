import SwiftUI
import UIKit

// Hallmark · genre: editorial · macrostructure: Catalogue
// theme: cool limestone paper · dark: ink canvas · accent: brass TOP only
// P5 H5 E4 S5 R5 V4 — no cream, no av.by blue, no purple

enum AutoraTheme {
    static let canvas = Color(
        light: Color(red: 230 / 255, green: 232 / 255, blue: 229 / 255),
        dark: Color(red: 9 / 255, green: 10 / 255, blue: 9 / 255)
    )
    static let surface = Color(
        light: Color(red: 242 / 255, green: 243 / 255, blue: 241 / 255),
        dark: Color(red: 18 / 255, green: 20 / 255, blue: 18 / 255)
    )
    static let ink = Color(
        light: Color(red: 20 / 255, green: 22 / 255, blue: 21 / 255),
        dark: Color(red: 230 / 255, green: 232 / 255, blue: 229 / 255)
    )
    static let muted = Color(
        light: Color(red: 108 / 255, green: 112 / 255, blue: 110 / 255),
        dark: Color(red: 138 / 255, green: 142 / 255, blue: 140 / 255)
    )
    static let accent = Color(
        light: Color(red: 42 / 255, green: 45 / 255, blue: 44 / 255),
        dark: Color(red: 197 / 255, green: 200 / 255, blue: 197 / 255)
    )
    static let price = ink
    static let badgeTop = Color(red: 154 / 255, green: 139 / 255, blue: 92 / 255)
    static let danger = Color(
        light: Color(red: 122 / 255, green: 61 / 255, blue: 56 / 255),
        dark: Color(red: 212 / 255, green: 168 / 255, blue: 164 / 255)
    )
    static let hairline = Color(
        light: Color(red: 20 / 255, green: 22 / 255, blue: 21 / 255).opacity(0.14),
        dark: Color(red: 230 / 255, green: 232 / 255, blue: 229 / 255).opacity(0.18)
    )
    static let photoRadius: CGFloat = 24
    static let chipRadius: CGFloat = 4
    static let specRadius: CGFloat = 4
    static let cardPhotoHeight: CGFloat = 360
    static let detailPhotoHeight: CGFloat = 460
    static let pageGutter: CGFloat = 20
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
