import SwiftUI

@main
struct AutoraApp: App {
    @State private var model = UITestLaunch.makeModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
                .tint(AutoraTheme.accent)
                .onOpenURL { model.handleDeepLink($0) }
        }
    }
}
