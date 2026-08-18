import SwiftUI

struct RootTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            Tab(value: AutoraTab.search) {
                SearchHubView()
            } label: {
                tabLabel("Каталог", systemImage: "car.fill", id: AutoraID.tabSearch)
            }
            Tab(value: AutoraTab.favorites) {
                GarageView()
            } label: {
                tabLabel("Гараж", systemImage: "bookmark.fill", id: AutoraID.tabFavorites)
            }
            Tab(value: AutoraTab.listings) {
                MyListingsView()
            } label: {
                tabLabel("Объявления", systemImage: "plus.circle.fill", id: AutoraID.tabListings)
            }
            Tab(value: AutoraTab.messages) {
                MessagesView()
            } label: {
                tabLabel("Сообщения", systemImage: "envelope.fill", id: AutoraID.tabMessages)
            }
            .badge(model.unreadCount)
            Tab(value: AutoraTab.profile) {
                ProfileView()
            } label: {
                tabLabel("Профиль", systemImage: "person.fill", id: AutoraID.tabProfile)
            }
        }
        .toolbarBackground(AutoraTheme.canvas, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sensoryFeedback(.selection, trigger: model.selectedTab)
        .overlay(alignment: .bottom) {
            if let toast = model.toastMessage {
                ToastBanner(text: toast)
                    .padding(.bottom, 72)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: toast) {
                        try? await Task.sleep(for: .seconds(3.8))
                        if model.toastMessage == toast {
                            model.toastMessage = nil
                        }
                    }
            }
        }
        .animation(AutoraMotion.enter, value: model.toastMessage)
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

struct ToastBanner: View {
    var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bookmark.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(AutoraTheme.garageBlue, in: Circle())
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 16, y: 8)
    }
}
