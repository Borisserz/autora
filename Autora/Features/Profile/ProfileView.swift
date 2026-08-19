/* Hallmark · pre-emit critique: P5 H5 E4 S5 R4 V4 */
import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var phone = ""
    @State private var name = ""
    @State private var path = NavigationPath()
    @State private var showVIN = false
    @State private var showValuation = false
    @State private var showCompare = false
    @State private var showCatalog = false

    private var snap: ProfileSnapshot { model.profileSnapshot }

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ticket
                    identity
                    ledger
                    tools
                    market
                    if snap.viewed > 0 { recent }
                    if snap.blocked > 0 { blocked }
                    if snap.reports > 0 { reports }
                    if snap.isSignedIn { signOut }
                    Text("\(CoolAVCopy.wordmark) · \(ProfileDesk.rateLine(snap.usdBYN))")
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(AutoraTheme.muted)
                }
                .padding(.horizontal, AutoraTheme.pageGutter)
                .padding(.bottom, 36)
            }
            .paperCanvas()
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { id in
                if let listing = model.listing(id: id) {
                    ListingDetailView(listing: listing)
                }
            }
            .sheet(isPresented: $showVIN) { VinCheckView() }
            .sheet(isPresented: $showValuation) { ValuationView() }
            .sheet(isPresented: $showCompare) {
                NavigationStack { CompareView() }
            }
            .sheet(isPresented: $showCatalog) { ModelCatalogView() }
            .onAppear(perform: hydrate)
            .onChange(of: model.session) { _, _ in hydrate() }
        }
    }

    private var ticket: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(ProfileDesk.kicker(snap.isSignedIn))
                .font(.caption.monospaced().weight(.bold))
                .tracking(1.6)
            Text(model.profileHeadline)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(AutoraTheme.canvas)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.profileHeadline)
    }

    @ViewBuilder
    private var identity: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Аккаунт")
            if snap.isSignedIn {
                field("Имя", text: $name, keyboard: .default)
                HStack(spacing: 8) {
                    field("Телефон", text: $phone, keyboard: .phonePad)
                        .onChange(of: phone) { _, value in
                            let formatted = BelarusPhone.display(value)
                            if formatted != value { phone = formatted }
                        }
                    if !phone.isEmpty {
                        Button {
                            PhoneClipboard.copy(BelarusPhone.e164(phone))
                            model.flash("Телефон скопирован", symbol: "phone.fill")
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AutoraTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .accessibilityLabel("Скопировать телефон")
                    }
                }
                if !snap.canPost {
                    Text("Без полного номера объявление не уйдёт в ленту.")
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.ink)
                }
                Button("Сохранить") {
                    model.updateProfile(name: name, phone: phone)
                    hydrate()
                }
                .font(.body.weight(.bold))
                .foregroundStyle(AutoraTheme.canvas)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .buttonStyle(PressableInkStyle())
            } else {
                Button("Войти (демо)") {
                    model.signInDemo()
                }
                .font(.body.weight(.bold))
                .foregroundStyle(AutoraTheme.canvas)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .buttonStyle(PressableInkStyle())
                Text("Apple / Google на TestFlight без plist Firebase — локальная сессия. Нужна, чтобы продавать и писать.")
                    .font(.footnote)
                    .foregroundStyle(AutoraTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var ledger: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Сводка")
                .padding(.bottom, 10)
            ledgerRow("объявления", value: "\(snap.listings)") {
                model.selectedTab = .listings
            }
            hairline
            ledgerRow("гараж", value: "\(snap.garage)") {
                model.selectedTab = .favorites
            }
            hairline
            ledgerRow("сообщения", value: snap.unread > 0 ? "\(snap.unread)" : "\(model.chats.count)") {
                if model.unreadCount > 0 { model.inboxTab = .unread }
                model.selectedTab = .messages
            }
            hairline
            ledgerRow("сравнение", value: "\(snap.compare)/\(CompareSet.limit)") {
                showCompare = true
            }
        }
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Инструменты")
            toolRow(kicker: "VIN", title: "Проверка VIN", detail: "17 знаков — сверка с карточкой") {
                showVIN = true
            }
            toolRow(kicker: "CMP", title: "Сравнение", detail: "Два лота рядом: цена, пробег, срок") {
                showCompare = true
            }
            toolRow(kicker: "EST", title: "Оценка", detail: "Рынок по марке, году и состоянию") {
                showValuation = true
            }
            toolRow(kicker: "CAT", title: "Каталог моделей", detail: "Поколения, годы, типичный пробег") {
                showCatalog = true
            }
        }
    }

    private var market: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Цена на экране")
            Toggle(isOn: Bindable(model).showUSD) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("USD крупно")
                        .font(.body.weight(.semibold))
                    Text("Br всегда рядом. В данных цена — белорусские рубли.")
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(AutoraTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(ProfileDesk.rateLine(snap.usdBYN))
                .font(.footnote.monospacedDigit().weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Недавно смотрели")
                Spacer()
                Button("Очистить") { model.clearRecentlyViewed() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AutoraTheme.ink)
                    .frame(minHeight: 44)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.recentlyViewedIDs.compactMap(model.listing(id:)), id: \.id) { listing in
                        Button {
                            path.append(listing.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                if let url = listing.photoURLs.first {
                                    AutoraRemotePhoto(urlString: url, height: 88)
                                        .frame(width: 140, height: 88)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                } else {
                                    AutoraTheme.surface
                                        .frame(width: 140, height: 88)
                                        .overlay {
                                            Image(systemName: "car.fill")
                                                .foregroundStyle(AutoraTheme.muted)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }
                                Text(listing.title)
                                    .font(.footnote.weight(.semibold))
                                    .lineLimit(1)
                                Text(
                                    PriceDisplay.pair(
                                        byn: listing.priceBYN,
                                        rate: model.fx.usdBYN,
                                        showUSD: model.showUSD
                                    ).primary
                                )
                                .font(.footnote.monospacedDigit())
                            }
                            .frame(width: 140, alignment: .leading)
                            .foregroundStyle(AutoraTheme.ink)
                        }
                        .buttonStyle(PressableInkStyle())
                    }
                }
            }
        }
    }

    private var blocked: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Скрытые продавцы")
            ForEach(model.blockedSellers) { seller in
                HStack {
                    Text(seller.name)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Button("Показать") { model.unblock(sellerID: seller.id) }
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .foregroundStyle(AutoraTheme.ink)
            }
        }
    }

    private var reports: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Жалобы")
            ForEach(model.reports) { report in
                Button {
                    if model.listing(id: report.listingID) != nil {
                        path.append(report.listingID)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ProfileDesk.reportReason(report.reason))
                                .font(.body.weight(.semibold))
                            Text(model.listing(id: report.listingID)?.title ?? "Объявление недоступно")
                                .font(.footnote)
                                .foregroundStyle(AutoraTheme.muted)
                                .lineLimit(1)
                        }
                        Spacer()
                        if model.listing(id: report.listingID) != nil {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AutoraTheme.muted)
                        }
                    }
                    .foregroundStyle(AutoraTheme.ink)
                    .frame(minHeight: 44)
                }
                .buttonStyle(PressableInkStyle())
                .disabled(model.listing(id: report.listingID) == nil)
            }
        }
    }

    private var signOut: some View {
        Button("Выйти", role: .destructive, action: model.signOut)
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(PressableInkStyle())
    }

    private var hairline: some View {
        Rectangle()
            .fill(AutoraTheme.hairline)
            .frame(height: 1)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AutoraTheme.muted)
    }

    private func field(_ title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(keyboard == .phonePad ? .never : .words)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func ledgerRow(_ title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(value)
                    .font(.body.monospacedDigit().weight(.bold))
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AutoraTheme.muted)
            }
            .foregroundStyle(AutoraTheme.ink)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableInkStyle())
        .accessibilityLabel("\(title), \(value)")
    }

    private func toolRow(kicker: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(kicker)
                    .font(.caption.monospaced().weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AutoraTheme.muted)
                    .frame(width: 36, alignment: .leading)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AutoraTheme.muted)
                    .padding(.top, 4)
            }
            .foregroundStyle(AutoraTheme.ink)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableInkStyle())
        .accessibilityLabel("\(title). \(detail)")
    }

    private func hydrate() {
        if let profile = model.session.profile {
            name = profile.name
            phone = BelarusPhone.display(profile.phone)
        } else {
            name = ""
            phone = ""
        }
    }
}
