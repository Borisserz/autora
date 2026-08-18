import SwiftUI

// Hallmark · macrostructure: Catalogue · tone: editorial letterpress
// theme: limestone / ink · motion: zoom · stagger · ink-press
// P5 H5 E4 S5 R5 V4

enum AutoraMotion {
    static let enter = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.42)
    static let exit = Animation.timingCurve(0.7, 0, 0.84, 0, duration: 0.22)
    static let press = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.12)
    static let hairline = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)

    static func stagger(index: Int) -> Animation {
        enter.delay(min(Double(index) * 0.055, 0.42))
    }
}

struct PressableInkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(AutoraMotion.press, value: configuration.isPressed)
    }
}

struct CatalogReveal: ViewModifier {
    var index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 12)
            .onAppear {
                if reduceMotion {
                    shown = true
                    return
                }
                withAnimation(AutoraMotion.stagger(index: index)) {
                    shown = true
                }
            }
    }
}

extension View {
    func catalogReveal(index: Int) -> some View {
        modifier(CatalogReveal(index: index))
    }

    func paperCanvas() -> some View {
        modifier(PaperCanvas())
    }
}

private struct PaperCanvas: ViewModifier {
    func body(content: Content) -> some View {
        content.background {
            AutoraTheme.canvas
                .ignoresSafeArea()
        }
    }
}

struct InkHairline: View {
    @State private var drawn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 3) {
            Rectangle()
                .fill(AutoraTheme.ink)
                .frame(height: 1)
            Rectangle()
                .fill(AutoraTheme.hairline)
                .frame(height: 1)
        }
        .scaleEffect(x: drawn ? 1 : 0.04, y: 1, anchor: .leading)
        .onAppear {
            if reduceMotion {
                drawn = true
                return
            }
            withAnimation(AutoraMotion.hairline) {
                drawn = true
            }
        }
    }
}
