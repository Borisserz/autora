import SwiftUI

struct MyListingsView: View {
    @Environment(AppModel.self) private var model
    @State private var showWizard = false
    @State private var path = NavigationPath()
    @State private var pendingDeleteID: String?

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $path) {
            Group {
                if !model.session.isSignedIn {
                    EmptyStateView(
                        title: "Мои объявления",
                        text: "Войдите, чтобы подавать, поднимать и править объявления.",
                        illustration: .listings,
                        actionTitle: "Войти",
                        action: {
                            if RemoteChatStore.isLive { model.selectedTab = .profile } else { model.signInDemo() }
                        }
                    )
                } else {
                    desk
                }
            }
            .paperCanvas()
            .navigationTitle("Объявления")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { id in
                if let listing = model.listing(id: id) {
                    ListingDetailView(listing: listing)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Новое объявление", systemImage: "plus") {
                        model.prepareNewListing()
                        signInAndPost()
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier(AutoraID.newListing)
                }
            }
            .sheet(isPresented: $showWizard) {
                PostWizardView()
            }
            .onAppear {
                openPendingWizardIfNeeded()
            }
            .onChange(of: model.pendingOpenWizard) { _, open in
                if open { openPendingWizardIfNeeded() }
            }
            .confirmationDialog(
                "Удалить объявление?",
                isPresented: Binding(
                    get: { pendingDeleteID != nil },
                    set: { if !$0 { pendingDeleteID = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    if let id = pendingDeleteID { model.deleteListing(id) }
                    pendingDeleteID = nil
                }
                Button("Отмена", role: .cancel) { pendingDeleteID = nil }
            }
        }
    }

    private func signInAndPost() {
        if !model.session.isSignedIn, !RemoteChatStore.isLive { model.signInDemo() }
        showWizard = true
    }

    private func openPendingWizardIfNeeded() {
        guard model.pendingOpenWizard else { return }
        model.pendingOpenWizard = false
        signInAndPost()
    }

    private var desk: some View {
        VStack(spacing: 0) {
            bayTicket
            if !model.myListings.isEmpty {
                tabPills
            }
            tabBody
        }
    }

    private var bayTicket: some View {
        let ready = SellerDesk.bumpReady(in: model.myListings, now: model.now()).count
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("DESK")
                    .font(.caption.monospaced().weight(.bold))
                    .tracking(1.6)
                Text(model.sellerHeadline)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            Text("Счётчики своих лотов сохраняются на устройстве.")
                .font(.caption)
                .foregroundStyle(AutoraTheme.canvas.opacity(0.72))
            if ready > 0 {
                Button(ready == 1 ? "Поднять объявление" : "Поднять все (\(ready))") {
                    model.bumpAllReady(at: Date(timeIntervalSince1970: model.now()))
                }
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(AutoraTheme.ink)
                .background(AutoraTheme.canvas, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .buttonStyle(PressableInkStyle())
            }
        }
        .foregroundStyle(AutoraTheme.canvas)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .padding(.horizontal, AutoraTheme.pageGutter)
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.sellerHeadline)
    }

    private var tabPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SellerDeskTab.allCases) { item in
                    let count = SellerDesk.count(item, in: model.myListings)
                    Button {
                        model.sellerDeskTab = item
                    } label: {
                        HStack(spacing: 8) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text("\(count)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(model.sellerDeskTab == item ? AutoraTheme.canvas.opacity(0.7) : AutoraTheme.muted)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .foregroundStyle(model.sellerDeskTab == item ? AutoraTheme.canvas : AutoraTheme.ink)
                        .background(
                            model.sellerDeskTab == item ? AutoraTheme.ink : AutoraTheme.surface,
                            in: RoundedRectangle(cornerRadius: AutoraTheme.chipRadius, style: .continuous)
                        )
                    }
                    .buttonStyle(PressableInkStyle())
                    .accessibilityLabel("\(item.title), \(count)")
                    .accessibilityAddTraits(model.sellerDeskTab == item ? .isSelected : [])
                }
            }
            .padding(.horizontal, AutoraTheme.pageGutter)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var tabBody: some View {
        let items = SellerDesk.listings(model.myListings, tab: model.sellerDeskTab)
        if model.myListings.isEmpty {
            GarageStyleEmpty(
                title: "Пока нет объявлений",
                text: "Подача занимает пару минут. Нужны свои фото и телефон в профиле.",
                actionTitle: "Подать объявление",
                action: {
                    model.prepareNewListing()
                    showWizard = true
                }
            )
        } else if items.isEmpty {
            GarageStyleEmpty(
                title: "В этом разделе пусто",
                text: "Переключите фильтр или подайте новое объявление.",
                actionTitle: "Показать все",
                action: { model.sellerDeskTab = .all }
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(items) { listing in
                        SellerListingCard(
                            listing: listing,
                            now: model.now(),
                            onOpen: { path.append(listing.id) },
                            onEdit: { model.beginEdit(listing.id) },
                            onDuplicate: { model.duplicateAsDraft(listing.id) },
                            onBump: { model.bump(listing.id, at: Date(timeIntervalSince1970: model.now())) },
                            onStatus: { model.setListingStatus(listing.id, $0) },
                            onDelete: { pendingDeleteID = listing.id }
                        )
                    }
                }
                .padding(.horizontal, AutoraTheme.pageGutter)
                .padding(.bottom, 28)
            }
        }
    }
}

private struct GarageStyleEmpty: View {
    var title: String
    var text: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image("EmptyListings")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220)
                .clipShape(RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
            Text(text)
                .font(.body)
                .foregroundStyle(AutoraTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button(actionTitle, action: action)
                .font(.body.weight(.bold))
                .foregroundStyle(AutoraTheme.canvas)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                .buttonStyle(PressableInkStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
}

private struct SellerListingCard: View {
    let listing: Listing
    var now: TimeInterval
    var onOpen: () -> Void
    var onEdit: () -> Void
    var onDuplicate: () -> Void
    var onBump: () -> Void
    var onStatus: (ListingStatus) -> Void
    var onDelete: () -> Void

    private var canBump: Bool {
        listing.status == .active && BumpPolicy.canBump(lastBumped: listing.bumpedAt, now: now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ListingCardView(
                listing: listing,
                showsCompare: false,
                showsFavorite: false,
                showsGarage: false,
                onOpen: onOpen
            )
            HStack {
                Text(listing.status.title)
                    .font(.caption.weight(.bold))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .foregroundStyle(listing.status == .active ? AutoraTheme.canvas : AutoraTheme.ink)
                    .background(
                        listing.status == .active ? AutoraTheme.ink : AutoraTheme.surface,
                        in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                    )
                Spacer()
                Text("\(listing.views) просм. · \(listing.favoritesCount) в избранном")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AutoraTheme.muted)
            }
            if listing.status == .active {
                if canBump {
                    Button("Поднять в ленте", action: onBump)
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(AutoraTheme.canvas)
                        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                        .buttonStyle(PressableInkStyle())
                } else {
                    Text("Поднять через \(BumpPolicy.hoursUntilBump(lastBumped: listing.bumpedAt, now: now)) ч")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AutoraTheme.muted)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                deskButton("Изменить", action: onEdit)
                deskButton("Копия", action: onDuplicate)
                if listing.status == .active {
                    deskButton("Снять") { onStatus(.inactive) }
                    deskButton("Продано") { onStatus(.sold) }
                } else {
                    deskButton("Вернуть в ленту") { onStatus(.active) }
                    Color.clear.frame(minHeight: 44)
                }
            }
            Button("Удалить", role: .destructive, action: onDelete)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(PressableInkStyle())
        }
    }

    private func deskButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(AutoraTheme.ink)
            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
            .buttonStyle(PressableInkStyle())
    }
}
