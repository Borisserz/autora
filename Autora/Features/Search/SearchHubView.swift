import SwiftUI

struct SearchHubView: View {
    @Environment(AppModel.self) private var model
    @State private var showFilters = false
    @State private var showCompare = false
    @State private var showVIN = false
    @State private var showValuation = false
    @State private var savedFlash = false
    @State private var path = NavigationPath()
    @State private var revealedIDs: Set<String> = []
    @Namespace private var catalog
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HubHero(
                            onPost: { model.selectedTab = .listings },
                            onVIN: { showVIN = true },
                            onValuation: { showValuation = true },
                            onShowCatalog: {
                                withAnimation(AutoraMotion.press) {
                                    proxy.scrollTo("catalog", anchor: .top)
                                }
                            },
                            onOpenFilters: { showFilters = true },
                            onSaveSearch: {
                                model.saveCurrentSearch()
                                savedFlash = true
                            },
                            savedFlash: savedFlash
                        )
                        MarketTickerView()
                        HubCatalogHeader()
                            .id("catalog")
                        if let loadError = model.loadError {
                            EmptyStateView(
                                title: "Каталог недоступен",
                                text: loadError,
                                illustration: .search,
                                actionTitle: "Повторить",
                                action: { model.retryLoad() }
                            )
                            .frame(minHeight: 240)
                            .padding(.horizontal, AutoraTheme.pageGutter)
                        } else if model.filtered.isEmpty {
                            EmptyStateView(
                                title: "По вашему запросу авто не найдены",
                                text: "Попробуйте изменить критерии поиска или сбросить фильтры, чтобы увидеть все предложения CoolAV.",
                                illustration: .search,
                                actionTitle: "Сбросить все фильтры",
                                action: { model.criteria = SearchCriteria() }
                            )
                            .frame(minHeight: 220)
                            .padding(.horizontal, AutoraTheme.pageGutter)
                        } else {
                            feed
                                .padding(.horizontal, AutoraTheme.pageGutter)
                                .padding(.top, 8)
                        }
                        if !model.recentlyViewedIDs.isEmpty {
                            recent
                                .padding(AutoraTheme.pageGutter)
                        }
                    }
                    .padding(.bottom, 40)
                    .containerRelativeFrame(.horizontal, alignment: .top)
                }
            }
            .paperCanvas()
            .refreshable { model.retryLoad() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                if let listing = model.listing(id: id) {
                    ListingDetailView(listing: listing)
                        .navigationTransition(.zoom(sourceID: id, in: catalog))
                }
            }
            .sheet(isPresented: $showFilters) {
                FiltersSheet()
            }
            .sheet(isPresented: $showCompare) {
                NavigationStack {
                    CompareView()
                }
            }
            .sheet(isPresented: $showVIN) {
                VinCheckView()
            }
            .sheet(isPresented: $showValuation) {
                ValuationView()
            }
            .safeAreaInset(edge: .bottom) {
                if model.compareIDs.count >= 2 {
                    compareBar
                }
            }
            .onAppear(perform: consumePendingLink)
            .onChange(of: model.pendingListingID) { _, _ in
                consumePendingLink()
            }
        }
    }

    private func consumePendingLink() {
        guard let id = model.pendingListingID else { return }
        model.pendingListingID = nil
        path.append(id)
    }

    private var feed: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(model.filtered.enumerated()), id: \.element.id) { index, listing in
                ListingFeedRow(
                    listing: listing,
                    onOpen: { path.append(listing.id) },
                    onOpenVIN: { showVIN = true },
                    onOpenCompare: {
                        if model.compareIDs.count >= 2 { showCompare = true }
                    }
                )
                .matchedTransitionSource(id: listing.id, in: catalog)
                .opacity(revealedIDs.contains(listing.id) ? 1 : 0)
                .offset(y: revealedIDs.contains(listing.id) ? 0 : 12)
                .onAppear { reveal(listing.id, index: index) }
            }
        }
    }

    private func reveal(_ id: String, index: Int) {
        guard !revealedIDs.contains(id) else { return }
        if reduceMotion {
            revealedIDs.insert(id)
            return
        }
        withAnimation(AutoraMotion.stagger(index: index)) {
            revealedIDs.insert(id)
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Недавно смотрели")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AutoraTheme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(model.recentlyViewedIDs.compactMap(model.listing(id:)), id: \.id) { listing in
                        Button {
                            path.append(listing.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                if let url = listing.photoURLs.first {
                                    AutoraRemotePhoto(urlString: url, height: 96)
                                        .frame(width: 148, height: 96)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                Text(listing.title)
                                    .font(.footnote.weight(.semibold))
                                    .lineLimit(1)
                                Text(PriceConverter.formatUSD(PriceConverter.usd(fromBYN: listing.priceBYN, rate: model.fx.usdBYN)))
                                    .font(.footnote.monospacedDigit())
                            }
                            .frame(width: 148, alignment: .leading)
                            .foregroundStyle(AutoraTheme.ink)
                        }
                    }
                }
            }
        }
    }

    private var compareBar: some View {
        HStack {
            Text("\(model.compareIDs.count) в сравнении")
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
            Spacer()
            Button("Сравнить") { showCompare = true }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AutoraTheme.ink, in: Capsule())
        }
        .padding(.horizontal, AutoraTheme.pageGutter)
        .padding(.vertical, 12)
        .background(AutoraTheme.canvas.opacity(0.96))
    }
}

private struct HubHero: View {
    @Environment(AppModel.self) private var model
    var onPost: () -> Void
    var onVIN: () -> Void
    var onValuation: () -> Void
    var onShowCatalog: () -> Void
    var onOpenFilters: () -> Void
    var onSaveSearch: () -> Void
    var savedFlash: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            islandNav
            Text(CoolAVCopy.heroBadge)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.black.opacity(0.5), in: Capsule())
                .frame(maxWidth: .infinity)
            Text(CoolAVCopy.heroTitle)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.45), radius: 8)
                .frame(maxWidth: .infinity)
            HubSearchWidget(
                onShowCatalog: onShowCatalog,
                onOpenFilters: onOpenFilters,
                onSaveSearch: onSaveSearch,
                savedFlash: savedFlash
            )
        }
        .padding(.horizontal, AutoraTheme.pageGutter)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .background { backdrop }
    }

    private var islandNav: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "scalemass.fill")
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.15), in: Circle())
                Text(CoolAVCopy.brand)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(".by")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            Spacer(minLength: 4)
            islandIcon("checkmark.shield.fill", label: "VIN", action: onVIN)
            islandIcon("chart.line.uptrend.xyaxis", label: "Оценка", action: onValuation)
            Button(action: onPost) {
                Text("+ Подать")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(PressableInkStyle())
            .accessibilityLabel("Подать объявление")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(.black.opacity(0.55)))
                .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
        }
    }

    private func islandIcon(_ system: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(PressableInkStyle())
        .accessibilityLabel(label)
    }

    private var backdrop: some View {
        Color.black
            .overlay {
                ZStack {
                    if let url = model.listings.first?.photoURLs.first {
                        AutoraRemotePhoto(urlString: url, height: 420, accessibilityText: nil)
                            .overlay(Color.black.opacity(0.42))
                    }
                    LinearGradient(
                        colors: [.black.opacity(0.72), .black.opacity(0.28), .black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .clipped()
    }
}

private struct HubSearchWidget: View {
    @Environment(AppModel.self) private var model
    var onShowCatalog: () -> Void
    var onOpenFilters: () -> Void
    var onSaveSearch: () -> Void
    var savedFlash: Bool

    private let yearFromOptions = [2010, 2015, 2018, 2020, 2022]
    private let yearToOptions = [2020, 2022, 2024, 2026]
    private let priceUSDPresets = [15_000, 25_000, 35_000, 50_000]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AutoraTheme.muted)
                TextField(CoolAVCopy.searchPlaceholder, text: Bindable(model).criteria.query)
                    .textInputAutocapitalization(.never)
                    .font(.subheadline.weight(.medium))
                    .accessibilityIdentifier(AutoraID.searchField)
            }
            .padding(12)
            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                makeMenu
                modelMenu
                yearMenus
                priceMenu
            }

            HStack {
                Button(action: onOpenFilters) {
                    Label(
                        model.criteria.activeFilterCount > 0
                            ? "Фильтры \(model.criteria.activeFilterCount)"
                            : "Расширенные фильтры",
                        systemImage: "slider.horizontal.3"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AutoraTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .accessibilityIdentifier(AutoraID.filters)
                .buttonStyle(PressableInkStyle())
                if model.criteria.activeFilterCount > 0 {
                    Button("Сбросить", action: resetFilters)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AutoraTheme.bargainRed)
                }
                Spacer()
                Button("Сохранить поиск", action: onSaveSearch)
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier(AutoraID.saveSearch)
            }

            Button(action: onShowCatalog) {
                Label("Показать \(carWord(model.filtered.count))", systemImage: "magnifyingglass")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PressableInkStyle())

            if savedFlash {
                Text("Сохранено в Гараж → Поиски")
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
            }
        }
        .padding(12)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
    }

    private var makeMenu: some View {
        Menu {
            Button("Все марки") { setMake(nil) }
            ForEach(FilterCatalog.makes(in: model.listings), id: \.self) { make in
                Button(make) { setMake(make) }
            }
        } label: {
            HubFilterField(title: "Марка автомобиля", value: model.criteria.make ?? "Все марки")
        }
    }

    private var modelMenu: some View {
        Menu {
            Button("Все модели") { model.criteria.model = nil }
            ForEach(FilterCatalog.models(in: model.listings, make: model.criteria.make), id: \.self) { name in
                Button(name) { model.criteria.model = name }
            }
        } label: {
            HubFilterField(title: "Модель", value: model.criteria.model ?? "Все модели")
        }
    }

    private var yearMenus: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(yearCaption.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AutoraTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(spacing: 6) {
                Menu {
                    Button("Любой") { model.criteria.yearFrom = nil }
                    ForEach(yearFromOptions, id: \.self) { year in
                        Button("От \(year)") { model.criteria.yearFrom = year }
                    }
                } label: {
                    HubFilterValue(model.criteria.yearFrom.map { "От \($0)" } ?? "От")
                }
                Menu {
                    Button("Любой") { model.criteria.yearTo = nil }
                    ForEach(yearToOptions, id: \.self) { year in
                        Button("До \(year)") { model.criteria.yearTo = year }
                    }
                } label: {
                    HubFilterValue(model.criteria.yearTo.map { "До \($0)" } ?? "До")
                }
            }
        }
    }

    private var priceMenu: some View {
        Menu {
            Button("Любая цена") { model.criteria.priceTo = nil }
            ForEach(priceUSDPresets, id: \.self) { usd in
                Button(priceLabel(usd)) { setPriceMaxUSD(usd) }
            }
        } label: {
            HubFilterField(title: "Цена до ($ / BYN)", value: priceValue)
        }
    }

    private var yearCaption: String {
        let from = model.criteria.yearFrom.map(String.init) ?? "любой"
        let to = model.criteria.yearTo.map(String.init) ?? "любой"
        return "Год: от \(from) до \(to)"
    }

    private var priceValue: String {
        guard let byn = model.criteria.priceTo else { return "Любая цена" }
        return "До \(PriceConverter.formatUSD(Double(PriceConverter.filterUSD(fromBYN: byn, rate: model.fx.usdBYN))))"
    }

    private func priceLabel(_ usd: Int) -> String {
        let byn = PriceConverter.byn(fromUSD: Double(usd), rate: model.fx.usdBYN)
        return "До \(PriceConverter.formatUSD(Double(usd))) (≈ \(byn.formatted()) Br)"
    }

    private func setMake(_ make: String?) {
        model.criteria.make = make
        model.criteria.model = nil
        model.criteria.generation = nil
    }

    private func setPriceMaxUSD(_ usd: Int) {
        model.criteria.priceTo = PriceConverter.byn(fromUSD: Double(usd), rate: model.fx.usdBYN)
    }

    private func resetFilters() {
        model.criteria = SearchCriteria()
    }

    private func carWord(_ n: Int) -> String {
        let mod100 = n % 100
        let mod10 = n % 10
        if mod100 >= 11 && mod100 <= 14 { return "\(n) автомобилей" }
        if mod10 == 1 { return "\(n) автомобиль" }
        if mod10 >= 2 && mod10 <= 4 { return "\(n) автомобиля" }
        return "\(n) автомобилей"
    }
}

private struct HubFilterField: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AutoraTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HubFilterValue(value)
        }
    }
}

private struct HubFilterValue: View {
    let value: String
    init(_ value: String) { self.value = value }

    var body: some View {
        HStack {
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
                .lineLimit(1)
            Spacer(minLength: 4)
            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundStyle(AutoraTheme.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct HubCatalogHeader: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ListingCategoryTab.allCases) { tab in
                        CategoryChip(
                            tab: tab,
                            title: tab == .all
                                ? "\(tab.title) (\(model.listings.count))"
                                : tab.catalogTitle,
                            idleFill: AutoraTheme.canvas
                        )
                    }
                }
                .padding(6)
                .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, AutoraTheme.pageGutter)
            }
            .frame(maxWidth: .infinity)
            Text(CoolAVCopy.catalogEyebrow.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.6)
                .foregroundStyle(AutoraTheme.ink.opacity(0.5))
            Text("\(model.filtered.count.formatted()) объявлений")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(AutoraTheme.muted)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

private struct CategoryChip: View {
    @Environment(AppModel.self) private var model
    let tab: ListingCategoryTab
    let title: String
    var idleFill: Color = AutoraTheme.surface

    var body: some View {
        let on = model.criteria.category == tab
        Button {
            model.criteria.category = tab
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(on && tab == .warranty ? AutoraTheme.ink : (on ? .white : AutoraTheme.ink))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressableInkStyle())
    }

    private var fill: Color {
        let on = model.criteria.category == tab
        guard on else { return idleFill }
        switch tab {
        case .all: return AutoraTheme.ink
        case .bargain: return AutoraTheme.bargainRed
        case .ev: return AutoraTheme.garageBlue
        case .europe: return AutoraTheme.europeGreen
        case .warranty: return AutoraTheme.amber
        case .premium: return AutoraTheme.premiumPurple
        }
    }
}

struct MarketTickerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                Text(CoolAVCopy.liveMarket)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(AutoraTheme.bargainRed)
            .zIndex(1)

            Color.clear
                .overlay(alignment: .leading) {
                    if reduceMotion {
                        Text(CoolAVCopy.ticker[0])
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .padding(.leading, 12)
                    } else {
                        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { context in
                            let x = CGFloat(context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 32) / 32)
                            HStack(spacing: 24) {
                                ForEach(Array((CoolAVCopy.ticker + CoolAVCopy.ticker).enumerated()), id: \.offset) { _, line in
                                    Text(line)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.9))
                                        .fixedSize()
                                }
                            }
                            .offset(x: -x * 900)
                        }
                    }
                }
                .clipped()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(AutoraTheme.ink)
        .clipped()
    }
}
