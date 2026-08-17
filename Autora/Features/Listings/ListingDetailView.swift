import SwiftUI
import UIKit

struct ListingDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    let listing: Listing
    private var isOwn: Bool { model.session.profile?.id == listing.sellerId }
    @State private var showReport = false
    @State private var reportAccepted = false
    @State private var chatID: String?
    @State private var chatError: String?
    @State private var copied = false

    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    StretchyCatalogPhoto(urls: listing.photoURLs, title: listing.title)
                    VStack(alignment: .leading, spacing: 16) {
                        colophon
                        specPairs
                        Text(listing.description)
                            .font(.body)
                            .foregroundStyle(AutoraTheme.ink)
                        seller
                        quietActions
                        sellerListings
                        similar
                    }
                    .padding(.horizontal, AutoraTheme.pageGutter)
                    .padding(.bottom, 28)
                }
        }
        .paperCanvas()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink("Поделиться", item: "autora://listing/\(listing.id)")
            }
        }
        .safeAreaInset(edge: .bottom) {
            stickyBar
        }
        .navigationDestination(item: $chatID) { id in
            ChatThreadView(threadID: id)
        }
        .confirmationDialog("Жалоба", isPresented: $showReport) {
            Button("Спам") { submitReport("spam") }
            Button("Уже продано") { submitReport("sold") }
            Button("Мошенничество", role: .destructive) { submitReport("fraud") }
        }
        .alert("Жалоба принята", isPresented: $reportAccepted) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Мы разберём обращение. Объявление пока на месте.")
        }
        .alert("Чат", isPresented: Binding(
            get: { chatError != nil },
            set: { if !$0 { chatError = nil } }
        )) {
            Button("OK", role: .cancel) {}
            if chatError == ChatStartError.needAuth.localizedDescription {
                Button("Войти") { model.signInDemo() }
            }
        } message: {
            Text(chatError ?? "")
        }
        .onAppear { model.markViewed(listing.id) }
    }

    private var colophon: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(listing.title)
                    .font(.system(.title, design: .serif).weight(.semibold))
                    .foregroundStyle(AutoraTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if listing.isTop {
                    Text("ТОП")
                        .font(.caption.bold())
                        .foregroundStyle(AutoraTheme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AutoraTheme.badgeTop)
                }
                if listing.isDemo {
                    Text("Демо")
                        .font(.caption)
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(AutoraTheme.muted)
                }
                if listing.hasVIN {
                    Text("VIN")
                        .font(.caption)
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(AutoraTheme.muted)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(PriceConverter.formatBYN(listing.priceBYN))
                    .font(.largeTitle.monospacedDigit().weight(.semibold))
                    .foregroundStyle(AutoraTheme.price)
                if model.showUSD {
                    Text("≈ " + PriceConverter.formatUSDReference(PriceConverter.usd(fromBYN: listing.priceBYN, rate: model.fx.usdBYN)))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(AutoraTheme.muted)
                }
                Spacer(minLength: 8)
                Text(listing.city)
                    .font(.caption)
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(AutoraTheme.muted)
            }
            if let badge = MarketPrice.badge(for: listing, in: model.listings) {
                Text(MarketPrice.caption(badge))
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
            }
        }
    }

    private var specPairs: some View {
        let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 0) {
            ForEach(specItems, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.caption)
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(AutoraTheme.muted)
                    Text(item.1)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(AutoraTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
                }
            }
        }
    }

    private var specItems: [(String, String)] {
        var items: [(String, String)] = [
            ("Год", "\(listing.year)"),
            ("Пробег", "\(listing.mileageKm.formatted()) км"),
            ("Двигатель", "\(listing.engineLiters) л · \(listing.powerHp) л.с."),
            ("КПП", listing.transmission),
            ("Привод", listing.drivetrain),
            ("Топливо", listing.fuel),
            ("Кузов", listing.body),
            ("Город", "\(listing.city), \(listing.region)"),
            ("Учёт", listing.registered ? "На учёте" : "Снят"),
            ("Растаможен", listing.customsCleared ? "Да" : "Нет"),
            ("Руль", listing.wheel == .left ? "Левый" : "Правый")
        ]
        if let vin = listing.vin { items.append(("VIN", vin)) }
        if listing.bargaining { items.append(("Торг", "Возможен")) }
        if listing.exchange { items.append(("Обмен", "Возможен")) }
        return items
    }

    private var seller: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Продавец")
                .font(.caption)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AutoraTheme.muted)
            Text(listing.sellerName)
                .font(.body.weight(.semibold))
            Text("\(listing.sellerListingCount) объявлений")
                .font(.footnote)
                .foregroundStyle(AutoraTheme.muted)
        }
    }

    private var quietActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !isOwn, !listing.sellerPhone.isEmpty {
                Button(copied ? "Скопировано на 60 с" : "Скопировать \(listing.sellerPhone)") {
                    PhoneClipboard.copy(listing.sellerPhone)
                    model.recordPhoneReveal(listingID: listing.id)
                    copied = true
                }
                .font(.footnote)
                .foregroundStyle(AutoraTheme.ink)
            }
            HStack(spacing: 16) {
                Button(model.compareIDs.contains(listing.id) ? "В сравнении" : "Сравнить") {
                    model.toggleCompare(listing.id)
                }
                Button("Пожаловаться") { showReport = true }
                Button("Скрыть", role: .destructive) { model.block(sellerID: listing.sellerId) }
            }
            .font(.footnote)
            .foregroundStyle(AutoraTheme.muted)
        }
        .buttonStyle(.plain)
    }

    private var stickyBar: some View {
        Group {
            if isOwn {
                Text("Это ваше объявление")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                HStack(spacing: 0) {
                    Button {
                        do {
                            chatID = try model.startChat(for: listing)
                        } catch ChatStartError.needAuth {
                            chatError = ChatStartError.needAuth.localizedDescription
                        } catch ChatStartError.cannotMessageSelf {
                            chatError = "Нельзя писать себе"
                        } catch {
                            chatError = error.localizedDescription
                        }
                    } label: {
                        Text("Написать")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .accessibilityIdentifier(AutoraID.write)
                    if let url = PhoneLink.telURL(listing.sellerPhone) {
                        Rectangle()
                            .fill(AutoraTheme.canvas.opacity(0.25))
                            .frame(width: 1, height: 28)
                        Button {
                            model.recordPhoneReveal(listingID: listing.id)
                            openURL(url)
                        } label: {
                            Text("Позвонить")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .accessibilityIdentifier(AutoraID.call)
                    }
                }
            }
        }
        .foregroundStyle(AutoraTheme.canvas)
        .background(AutoraTheme.ink)
    }

    private var sellerListings: some View {
        let others = model.listings.filter {
            $0.sellerId == listing.sellerId && $0.id != listing.id && $0.status == .active
        }.prefix(4)
        return VStack(alignment: .leading, spacing: 16) {
            if !others.isEmpty {
                Text("Ещё у продавца")
                    .font(.caption)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AutoraTheme.muted)
                ForEach(Array(others)) { item in
                    NavigationLink(value: item.id) {
                        ListingCardView(listing: item, showsCompare: false, showsFavorite: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var similar: some View {
        let peers = model.listings.filter {
            $0.make == listing.make
                && $0.id != listing.id
                && $0.sellerId != listing.sellerId
                && $0.status == .active
        }.prefix(4)
        return VStack(alignment: .leading, spacing: 16) {
            if !peers.isEmpty {
                Text("Похожие")
                    .font(.caption)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AutoraTheme.muted)
                ForEach(Array(peers)) { item in
                    NavigationLink(value: item.id) {
                        ListingCardView(listing: item, showsCompare: false, showsFavorite: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func submitReport(_ reason: String) {
        model.report(listingID: listing.id, reason: reason)
        reportAccepted = true
    }
}
