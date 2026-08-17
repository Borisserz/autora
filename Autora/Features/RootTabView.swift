import SwiftUI

struct RootTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            Tab(value: AutoraTab.search) {
                SearchHubView()
            } label: {
                tabLabel("Поиск", systemImage: "magnifyingglass", id: AutoraID.tabSearch)
            }
            Tab(value: AutoraTab.favorites) {
                FavoritesView()
            } label: {
                tabLabel("Избранное", systemImage: "heart", id: AutoraID.tabFavorites)
            }
            Tab(value: AutoraTab.listings) {
                MyListingsView()
            } label: {
                tabLabel("Объявления", systemImage: "doc", id: AutoraID.tabListings)
            }
            Tab(value: AutoraTab.messages) {
                MessagesView()
            } label: {
                tabLabel("Сообщения", systemImage: "envelope", id: AutoraID.tabMessages)
            }
            .badge(model.unreadCount)
            Tab(value: AutoraTab.profile) {
                ProfileView()
            } label: {
                tabLabel("Профиль", systemImage: "person", id: AutoraID.tabProfile)
            }
        }
        .toolbarBackground(AutoraTheme.canvas, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sensoryFeedback(.selection, trigger: model.selectedTab)
        .modifier(TabMinimizeOnScroll())
    }

    private func tabLabel(_ title: String, systemImage: String, id: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .frame(width: 26, height: 26)
        }
        .accessibilityIdentifier(id)
    }
}

private struct TabMinimizeOnScroll: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}
