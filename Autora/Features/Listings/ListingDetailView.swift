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
    @State private var showVIN = false
    @State private var downPercent = 30
    @State private var leaseYears = 3
    @State private var showModelCatalog = false

    private var usd: Double {
        PriceConverter.usd(fromBYN: listing.priceBYN, rate: model.fx.usdBYN)
    }

    private var price: PriceDisplay.Pair {
        PriceDisplay.pair(byn: listing.priceBYN, rate: model.fx.usdBYN, showUSD: model.showUSD)
    }

    private var leaseBYN: Int {
        LeaseQuote.monthlyBYN(priceUSD: usd, downPercent: downPercent, years: leaseYears, usdBYN: model.fx.usdBYN)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StretchyCatalogPhoto(urls: listing.photoURLs, title: listing.title)
                    .overlay(alignment: .topLeading) {
                        if ListingTrust.showsVerifiedSeal(listing) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                Text(CoolAVCopy.verified)
                            }
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AutoraTheme.emerald)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(12)
                        } else if listing.isDemo {
                            Text("Демо-объявление")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .padding(12)
                        }
                    }
                VStack(alignment: .leading, spacing: 14) {
                    priceCard
                    sellerCard
                    actionTrio
                    leaseCard
                    specGrid
                    insightCard
                    if ListingTrust.showsSyntheticEquipment(listing) {
                        equipmentBlock
                    }
                    if !listing.description.isEmpty {
                        descriptionBlock
                    }
                    vinBanner
                    quietActions
                    sellerListings
                    similar
                }
                .padding(.horizontal, AutoraTheme.pageGutter)
                .padding(.bottom, 28)
            }
        }
        .background(AutoraTheme.detailCanvas)
        .toolbarBackground(AutoraTheme.detailCanvas, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(listing.make) • \(listing.year)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink("Поделиться", item: "autora://listing/\(listing.id)")
                    .foregroundStyle(.white)
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
                Button("Войти") {
                    if RemoteChatStore.isLive { model.selectedTab = .profile } else { model.signInDemo() }
                }
            }
        } message: {
            Text(chatError ?? "")
        }
        .sheet(isPresented: $showVIN) {
            VinCheckView(initialVin: listing.vin ?? "")
        }
        .sheet(isPresented: $showModelCatalog) {
            ModelCatalogView(initialID: ListingTrust.insight(for: listing)?.id)
        }
        .onAppear { model.markViewed(listing.id) }
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(PhoneClipboard.ttl))
            copied = false
        }
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(price.primary)
                    .font(.largeTitle.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                Spacer(minLength: 8)
                Text(price.secondary)
                    .font(.footnote.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            if let percent = MarketDeal.discountPercent(for: listing, in: model.listings) {
                Text("−\(percent)% ниже рынка РБ")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AutoraTheme.emerald)
            } else if let badge = MarketPrice.badge(for: listing, in: model.listings) {
                Text(MarketPrice.caption(badge))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(badge == "ниже рынка" ? AutoraTheme.emerald : .white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (badge == "ниже рынка" ? AutoraTheme.emerald : Color.white).opacity(0.16),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }
            HStack(spacing: 8) {
                Text(listing.city)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                if listing.isTop {
                    Text("ТОП")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AutoraTheme.bargainRed, in: Capsule())
                }
            }
            Text(listing.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var sellerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(String(listing.sellerName.prefix(1)))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AutoraTheme.emerald)
                    .frame(width: 40, height: 40)
                    .background(AutoraTheme.emerald.opacity(0.2), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(listing.sellerName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(listing.sellerListingCount) объявлений на CoolAV")
                        .font(.caption)
                        .foregroundStyle(AutoraTheme.emerald)
                }
            }
            if !isOwn, let url = PhoneLink.telURL(listing.sellerPhone) {
                Button {
                    model.recordPhoneReveal(listingID: listing.id)
                    openURL(url)
                } label: {
                    Label("Позвонить: \(BelarusPhone.display(listing.sellerPhone))", systemImage: "phone.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AutoraTheme.emerald, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressableInkStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var actionTrio: some View {
        HStack(spacing: 8) {
            detailAction(
                title: model.isDeferred(listing.id) ? "В гараже" : "В гараж",
                systemImage: model.isDeferred(listing.id) ? "bookmark.fill" : "bookmark",
                on: model.isDeferred(listing.id),
                tint: AutoraTheme.garageBlue
            ) {
                model.toggleDeferred(listing.id)
            }
            detailAction(
                title: model.favoriteIDs.contains(listing.id) ? "В избранном" : "Избранное",
                systemImage: model.favoriteIDs.contains(listing.id) ? "heart.fill" : "heart",
                on: model.favoriteIDs.contains(listing.id),
                tint: AutoraTheme.bargainRed
            ) {
                model.toggleFavorite(listing.id)
            }
            detailAction(
                title: model.compareIDs.contains(listing.id) ? "В сравнении" : "Сравнить",
                systemImage: "scalemass.fill",
                on: model.compareIDs.contains(listing.id),
                tint: AutoraTheme.amber
            ) {
                model.toggleCompare(listing.id)
            }
        }
    }

    private func detailAction(
        title: String,
        systemImage: String,
        on: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                on ? tint : Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(on ? tint : Color.white.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(PressableInkStyle())
    }

    private var leaseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Лизинг / кредит")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("от \(leaseBYN.formatted()) Br / мес")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("Без справок")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(red: 147 / 255, green: 197 / 255, blue: 253 / 255))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.25), in: Capsule())
            }
            HStack(spacing: 8) {
                Menu {
                    ForEach([20, 30, 50], id: \.self) { pct in
                        Button("Взнос \(pct)%") { downPercent = pct }
                    }
                } label: {
                    Text("Взнос \(downPercent)%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                Menu {
                    ForEach([2, 3, 5], id: \.self) { years in
                        Button("\(years) года") { leaseYears = years }
                    }
                } label: {
                    Text("\(leaseYears) года")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.28), Color.indigo.opacity(0.22)], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.blue.opacity(0.35), lineWidth: 1)
        }
    }

    private var specGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Технические характеристики")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(specItems, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.0)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .textCase(.uppercase)
                        Text(item.1)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var equipmentBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Комплектация")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(listing.equipment ?? [], id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AutoraTheme.emerald)
                        Text(item)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let insight = ListingTrust.insight(for: listing) {
                HStack {
                    Text(insight.tag)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AutoraTheme.amber)
                    Spacer()
                    Text(String(format: "%.1f / 10", insight.overall))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                Text(insight.model)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Содержание ~$\(insight.monthlyUSD) в месяц · каталог CoolAV, не этот экземпляр")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                scoreBar("Запчасти в РБ", insight.parts)
                scoreBar("Комфорт", insight.comfort)
                scoreBar("Надёжность", insight.reliability)
                if let pro = insight.pros.first {
                    Text("Плюс: \(pro)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !insight.weakSpots.isEmpty {
                    Text("Слабые места: \(insight.weakSpots)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Модель не в каталоге аналитики")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Плюсы и слабые места показываем только при точном совпадении марки и модели, без подстановки «похожего» авто.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Каталог моделей CoolAV") {
                showModelCatalog = true
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(AutoraTheme.emerald, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func scoreBar(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                Spacer()
                Text(String(format: "%.1f", value))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white)
            }
            ProgressView(value: value, total: 10)
                .tint(AutoraTheme.emerald)
        }
    }

    private var specItems: [(String, String)] {
        var items: [(String, String)] = [
            ("Год", "\(listing.year) г."),
            ("Пробег", "\(listing.mileageKm.formatted()) км"),
            ("Двигатель", ListingSpecs.engineLine(listing)),
            ("КПП", listing.transmission),
            ("Привод", listing.drivetrain),
            ("Топливо", listing.fuel),
            ("Кузов", listing.body),
            ("Город", "\(listing.city), \(listing.region)")
        ]
        if let insight = ListingTrust.insight(for: listing) {
            items.append(("Разгон 0–100", String(format: "%.1f сек · каталог", insight.acceleration0100)))
        }
        if listing.hasVIN, let vin = listing.vin { items.append(("VIN", vin)) }
        return items
    }

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Описание")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            Text(listing.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.86))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var vinBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Проверка VIN")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(listing.hasVIN
                     ? "VIN указан продавцом. Отчёт CoolAV — демо, не база ГАИ."
                     : "VIN не указан. Можно открыть демо-проверку без юридических выводов.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button("VIN") { showVIN = true }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var quietActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !isOwn, !listing.sellerPhone.isEmpty {
                Button(copied ? "Скопировано на 60 с" : "Скопировать \(BelarusPhone.display(listing.sellerPhone))") {
                    PhoneClipboard.copy(listing.sellerPhone)
                    model.recordPhoneReveal(listingID: listing.id)
                    copied = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            HStack(spacing: 16) {
                Button("Пожаловаться") { showReport = true }
                if model.blockedSellerIDs.contains(listing.sellerId) {
                    Button("Показать в ленте") { model.unblock(sellerID: listing.sellerId) }
                } else {
                    Button("Скрыть", role: .destructive) { model.block(sellerID: listing.sellerId) }
                }
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.45))
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
                    if PhoneLink.telURL(listing.sellerPhone) != nil {
                        Rectangle()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 1, height: 28)
                        Button {
                            model.recordPhoneReveal(listingID: listing.id)
                            if let url = PhoneLink.telURL(listing.sellerPhone) {
                                openURL(url)
                            }
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
        .foregroundStyle(.black)
        .background(AutoraTheme.emerald)
    }

    private var sellerListings: some View {
        let others = model.listings.filter {
            $0.sellerId == listing.sellerId && $0.id != listing.id && $0.status == .active
        }.prefix(4)
        return VStack(alignment: .leading, spacing: 16) {
            if !others.isEmpty {
                Text("Ещё у продавца")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .textCase(.uppercase)
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .textCase(.uppercase)
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
