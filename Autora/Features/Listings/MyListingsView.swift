import SwiftUI

struct MyListingsView: View {
    @Environment(AppModel.self) private var model
    @State private var showWizard = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if !model.session.isSignedIn {
                    EmptyStateView(
                        title: "Мои объявления",
                        text: "Войдите, чтобы подавать и поднимать объявления.",
                        illustration: .listings,
                        actionTitle: "Войти",
                        action: { model.signInDemo() }
                    )
                } else if model.myListings.isEmpty {
                    EmptyStateView(
                        title: "Пока нет объявлений",
                        text: "Подача занимает пару минут. Телефон должен быть в профиле. Нужны свои фото.",
                        illustration: .listings,
                        actionTitle: "Подать объявление",
                        action: { showWizard = true }
                    )
                } else {
                    listings
                }
            }
            .paperCanvas()
            .navigationTitle("Объявления")
            .navigationDestination(for: String.self) { id in
                if let listing = model.listing(id: id) {
                    ListingDetailView(listing: listing)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Новое объявление", systemImage: "plus") {
                        signInAndPost()
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier(AutoraID.newListing)
                }
            }
            .sheet(isPresented: $showWizard) {
                PostWizardView()
            }
        }
    }

    private func signInAndPost() {
        if !model.session.isSignedIn { model.signInDemo() }
        showWizard = true
    }

    private var listings: some View {
        let stats = SellerStats.from(model.myListings)
        let now = model.now()
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(stats.listingCount) объявл. · \(stats.views) просмотров")
                        .font(.footnote.monospacedDigit())
                    Text("В избранном \(stats.favorites) · звонки \(stats.phoneReveals)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(AutoraTheme.muted)
                }
                ForEach(model.myListings) { listing in
                    VStack(alignment: .leading, spacing: 10) {
                        ListingCardView(
                            listing: listing,
                            showsCompare: false,
                            showsFavorite: false,
                            showsGarage: false,
                            onOpen: { path.append(listing.id) }
                        )
                        HStack {
                            Text(statusLabel(listing.status))
                                .font(.caption)
                                .tracking(0.4)
                                .textCase(.uppercase)
                                .foregroundStyle(AutoraTheme.muted)
                            Spacer()
                            Text("Просмотры \(listing.views) · избранное \(listing.favoritesCount)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AutoraTheme.muted)
                        }
                        HStack(spacing: 16) {
                            let canBump = BumpPolicy.canBump(lastBumped: listing.bumpedAt, now: now)
                            Button("Поднять") { model.bump(listing.id) }
                                .disabled(!canBump)
                            if !canBump {
                                Text("через \(BumpPolicy.hoursUntilBump(lastBumped: listing.bumpedAt, now: now)) ч")
                                    .font(.caption)
                                    .foregroundStyle(AutoraTheme.muted)
                            }
                            Spacer()
                            if listing.status == .active {
                                Button("Снять") { model.setListingStatus(listing.id, .inactive) }
                                Button("Продано") { model.setListingStatus(listing.id, .sold) }
                            } else {
                                Button("Вернуть") { model.setListingStatus(listing.id, .active) }
                            }
                        }
                        .font(.subheadline)
                    }
                    Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
                }
            }
            .padding(20)
        }
    }

    private func statusLabel(_ status: ListingStatus) -> String {
        switch status {
        case .active: "Активно"
        case .sold: "Продано"
        case .inactive: "Снято"
        case .draft: "Черновик"
        }
    }
}
