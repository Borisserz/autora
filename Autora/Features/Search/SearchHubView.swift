import SwiftUI

struct SearchHubView: View {
    @Environment(AppModel.self) private var model
    @State private var showFilters = false
    @State private var showCompare = false
    @State private var savedFlash = false
    @State private var path = NavigationPath()
    @State private var revealedIDs: Set<String> = []
    @Namespace private var catalog
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    if let loadError = model.loadError {
                        EmptyStateView(
                            title: "Каталог недоступен",
                            text: loadError,
                            illustration: .search,
                            actionTitle: "Повторить",
                            action: { model.retryLoad() }
                        )
                        .frame(minHeight: 240)
                    } else {
                        saveSearchRow
                        brandRow
                        if let make = model.criteria.make {
                            taxonomyRow(
                                BrandCounter.modelCounts(in: model.listings, make: make),
                                selected: model.criteria.model,
                                onSelect: model.selectModel
                            )
                        }
                        if let make = model.criteria.make, let selectedModel = model.criteria.model {
                            taxonomyRow(
                                BrandCounter.generationCounts(in: model.listings, make: make, model: selectedModel),
                                selected: model.criteria.generation,
                                onSelect: model.selectGeneration
                            )
                        }
                        sortRow
                        if model.filtered.isEmpty {
                            EmptyStateView(
                                title: "Ничего не нашлось",
                                text: "Сбросьте фильтры или измените запрос.",
                                illustration: .search,
                                actionTitle: "Сбросить",
                                action: { model.criteria = SearchCriteria() }
                            )
                            .frame(minHeight: 180)
                        } else {
                            feed
                        }
                        if !model.recentlyViewedIDs.isEmpty {
                            recent
                        }
                    }
                }
                .padding(.horizontal, AutoraTheme.pageGutter)
                .padding(.bottom, 40)
            }
            .paperCanvas()
            .refreshable { model.retryLoad() }
            .safeAreaInset(edge: .top, spacing: 0) {
                searchField
                    .padding(.horizontal, AutoraTheme.pageGutter)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .background(AutoraTheme.canvas.opacity(0.94))
            }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Autora")
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(AutoraTheme.ink)
            HStack(alignment: .firstTextBaseline) {
                Text("\(model.filtered.count.formatted()) объявлений")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(AutoraTheme.muted)
                    .contentTransition(.numericText())
                    .animation(AutoraMotion.press, value: model.filtered.count)
                Spacer(minLength: 8)
                Text(issueLine)
                    .font(.caption)
                    .tracking(0.4)
                    .foregroundStyle(AutoraTheme.muted)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            InkHairline()
                .padding(.top, 4)
        }
        .padding(.top, 4)
    }

    private var issueLine: String {
        let day = Date.now.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "ru_BY")))
        return "Беларусь · \(day)"
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            TextField("Марка, модель, поколение", text: Bindable(model).criteria.query)
                .textInputAutocapitalization(.never)
                .font(.body)
                .accessibilityIdentifier(AutoraID.searchField)
            Button {
                showFilters = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.body)
                        .frame(minWidth: 44, minHeight: 44)
                    if model.criteria.activeFilterCount > 0 {
                        Text("\(model.criteria.activeFilterCount)")
                            .font(.caption2.monospacedDigit().weight(.bold))
                            .foregroundStyle(AutoraTheme.canvas)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AutoraTheme.ink)
                            .offset(x: 4, y: 4)
                    }
                }
            }
            .accessibilityLabel(
                model.criteria.activeFilterCount > 0
                    ? "Фильтры, \(model.criteria.activeFilterCount)"
                    : "Фильтры"
            )
            .accessibilityIdentifier(AutoraID.filters)
            .foregroundStyle(AutoraTheme.ink)
            .buttonStyle(PressableInkStyle())
        }
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
        }
    }

    private var saveSearchRow: some View {
        HStack {
            Button("Сохранить поиск") {
                model.saveCurrentSearch()
                savedFlash = true
            }
            .font(.caption)
            .foregroundStyle(AutoraTheme.ink)
            .buttonStyle(PressableInkStyle())
            .accessibilityIdentifier(AutoraID.saveSearch)
            if savedFlash {
                Text("в Избранное → Поиски")
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
            }
            Spacer()
            if model.criteria.activeFilterCount > 0 {
                Button("Сбросить \(model.criteria.activeFilterCount)") {
                    model.criteria = SearchCriteria()
                }
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
                .buttonStyle(PressableInkStyle())
            }
        }
    }

    private var brandRow: some View {
        Color.clear
            .frame(height: 52)
            .overlay(alignment: .leading) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(model.brandCounts) { brand in
                            let selected = model.criteria.make == brand.name
                            Button {
                                model.selectMake(brand.name)
                            } label: {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(brand.name)
                                        .font(.subheadline)
                                    Text("\(brand.count)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(selected ? AutoraTheme.canvas.opacity(0.7) : AutoraTheme.muted)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .foregroundStyle(selected ? AutoraTheme.canvas : AutoraTheme.ink)
                                .background(selected ? AutoraTheme.ink : Color.clear)
                                .overlay {
                                    RoundedRectangle(cornerRadius: AutoraTheme.chipRadius, style: .continuous)
                                        .stroke(selected ? AutoraTheme.ink : AutoraTheme.hairline, lineWidth: 1)
                                }
                            }
                            .buttonStyle(PressableInkStyle())
                        }
                    }
                }
            }
    }

    @ViewBuilder
    private func taxonomyRow(_ items: [BrandCount], selected: String?, onSelect: @escaping (String) -> Void) -> some View {
        if !items.isEmpty {
            Color.clear
                .frame(height: 52)
                .overlay(alignment: .leading) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(items) { item in
                                let isOn = selected == item.name
                                Button {
                                    onSelect(item.name)
                                } label: {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.name)
                                            .font(.subheadline)
                                        Text("\(item.count)")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(isOn ? AutoraTheme.canvas.opacity(0.7) : AutoraTheme.muted)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(isOn ? AutoraTheme.canvas : AutoraTheme.ink)
                                    .background(isOn ? AutoraTheme.ink : Color.clear)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: AutoraTheme.chipRadius, style: .continuous)
                                            .stroke(isOn ? AutoraTheme.ink : AutoraTheme.hairline, lineWidth: 1)
                                    }
                                }
                                .buttonStyle(PressableInkStyle())
                            }
                        }
                    }
                }
        }
    }

    private var sortRow: some View {
        Color.clear
            .frame(height: 28)
            .overlay(alignment: .leading) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(ListingSort.allCases) { sort in
                            Button(sort.title) { model.sort = sort }
                                .font(.footnote)
                                .bold(model.sort == sort)
                                .foregroundStyle(AutoraTheme.ink)
                                .padding(.bottom, 4)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(model.sort == sort ? AutoraTheme.ink : .clear)
                                        .frame(height: 1)
                                }
                        }
                    }
                }
            }
    }

    private var feed: some View {
        LazyVStack(spacing: 36) {
            ForEach(Array(model.filtered.enumerated()), id: \.element.id) { index, listing in
                ListingFeedRow(listing: listing) {
                    path.append(listing.id)
                }
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
                .font(.caption)
                .tracking(0.6)
                .textCase(.uppercase)
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
                                        .clipShape(RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                                }
                                Text(listing.title)
                                    .font(.system(.footnote, design: .serif).weight(.semibold))
                                    .lineLimit(1)
                                Text(PriceConverter.formatBYN(listing.priceBYN))
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
                .padding(.bottom, 2)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AutoraTheme.ink).frame(height: 1)
                }
        }
        .padding(.horizontal, AutoraTheme.pageGutter)
        .padding(.vertical, 12)
        .background(AutoraTheme.canvas.opacity(0.96))
    }
}
