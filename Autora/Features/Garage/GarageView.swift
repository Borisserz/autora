import SwiftUI

struct GarageView: View {
    @Environment(AppModel.self) private var model
    @State private var tab = 0
    @State private var path = NavigationPath()
    @State private var showAddCar = false
    @Namespace private var catalog

    private var tabs: [(String, Int)] {
        [
            ("Избранное", model.listings.filter { model.favoriteIDs.contains($0.id) }.count),
            ("Отложенные", model.listings.filter { model.isDeferred($0.id) }.count),
            ("Автопарк", model.ownedGarage.count),
            ("Поиски", model.savedSearches.count)
        ]
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, item in
                        Button {
                            tab = index
                        } label: {
                            Text(item.1 > 0 ? "\(item.0) \(item.1)" : item.0)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(tab == index ? .white : AutoraTheme.ink)
                                .background(
                                    tab == index ? AutoraTheme.ink : AutoraTheme.surface,
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                )
                        }
                        .buttonStyle(PressableInkStyle())
                    }
                }
                .padding(.horizontal, AutoraTheme.pageGutter)
                .padding(.top, 12)
                .padding(.bottom, 8)

                switch tab {
                case 0: bookmarks
                case 1: deferred
                case 2: fleet
                default: searches
                }
            }
            .paperCanvas()
            .navigationTitle("Мой Гараж")
            .navigationDestination(for: String.self) { id in
                if let listing = model.listing(id: id) {
                    ListingDetailView(listing: listing)
                        .navigationTransition(.zoom(sourceID: id, in: catalog))
                }
            }
            .sheet(isPresented: $showAddCar) {
                AddGarageCarView()
            }
        }
    }

    @ViewBuilder
    private var bookmarks: some View {
        listingStack(
            model.listings.filter { model.favoriteIDs.contains($0.id) },
            emptyTitle: "Пока пусто",
            emptyText: "Нажмите сердце на карточке, чтобы сохранить авто.",
            showsDrop: false
        )
    }

    @ViewBuilder
    private var deferred: some View {
        let items = model.listings.filter { model.isDeferred($0.id) }
        if items.isEmpty {
            EmptyStateView(
                title: "Ваш список отложенных покупок пуст",
                text: "Нажимайте «В гараж» на автомобилях в каталоге, чтобы следить за скидками.",
                illustration: .favorites,
                actionTitle: nil
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(items) { listing in
                        DeferredTrackerCard(listing: listing) {
                            path.append(listing.id)
                        }
                        .matchedTransitionSource(id: listing.id, in: catalog)
                    }
                }
                .padding(20)
            }
        }
    }

    @ViewBuilder
    private func listingStack(
        _ items: [Listing],
        emptyTitle: String,
        emptyText: String,
        showsDrop: Bool
    ) -> some View {
        if items.isEmpty {
            EmptyStateView(title: emptyTitle, text: emptyText, illustration: .favorites, actionTitle: nil)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(items) { listing in
                        VStack(alignment: .leading, spacing: 8) {
                            if showsDrop, let saved = PriceDrop.usdBelowMarket(
                                for: listing,
                                in: model.listings,
                                usdBYN: model.fx.usdBYN
                            ) {
                                Text("Цена ниже рынка · выгода \(PriceConverter.formatUSD(Double(saved)))")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AutoraTheme.emerald)
                                    .padding(.horizontal, 4)
                            }
                            ListingFeedRow(listing: listing) {
                                path.append(listing.id)
                            }
                            .matchedTransitionSource(id: listing.id, in: catalog)
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    @ViewBuilder
    private var fleet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Автомобили в вашей собственности")
                        .font(.system(.title3, design: .serif))
                    Spacer()
                    Button("Добавить") { showAddCar = true }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AutoraTheme.ink, in: Capsule())
                }
                if model.ownedGarage.isEmpty {
                    EmptyStateView(
                        title: "Автопарк пуст",
                        text: "Добавьте свою машину — оценка и напоминания останутся на устройстве.",
                        illustration: .favorites,
                        actionTitle: "Добавить авто",
                        action: { showAddCar = true }
                    )
                } else {
                    ForEach(model.ownedGarage) { car in
                        GarageFleetCard(car: car) {
                            model.removeOwned(car.id)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var searches: some View {
        if model.savedSearches.isEmpty {
            EmptyStateView(
                title: "Нет сохранённых поисков",
                text: "Сохраните фильтр с каталога — он останется на этом устройстве.",
                illustration: .search,
                actionTitle: nil
            )
        } else {
            List {
                ForEach(model.savedSearches) { search in
                    Button {
                        model.openSavedSearch(search)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(search.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AutoraTheme.ink)
                            Text("Откроется на вкладке Каталог")
                                .font(.footnote)
                                .foregroundStyle(AutoraTheme.muted)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Удалить", role: .destructive) {
                            model.deleteSavedSearch(search.id)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

private struct GarageFleetCard: View {
    @Environment(AppModel.self) private var model
    let car: OwnedGarageCar
    var onDelete: () -> Void

    private var price: PriceDisplay.Pair {
        PriceDisplay.pair(byn: car.currentValueBYN, rate: model.fx.usdBYN, showUSD: model.showUSD)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Group {
                    if let url = car.photoURL {
                        AutoraRemotePhoto(urlString: url, height: 160)
                    } else {
                        Rectangle()
                            .fill(AutoraTheme.surface)
                            .overlay {
                                Image(systemName: "car.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(AutoraTheme.muted)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .clipped()

                HStack(spacing: 6) {
                    Text("Мой автопарк")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AutoraTheme.garageBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(car.city)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Spacer(minLength: 4)
                    if let plate = car.licensePlate, !plate.isEmpty {
                        Text(plate)
                            .font(.caption2.monospaced().weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("\(car.year) год • \(car.city)")
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
                Text(car.title)
                    .font(.system(.title3, design: .serif))
                Text("Пробег: \(car.mileageKm.formatted()) км • \(car.engine)")
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Рыночная оценка CoolAV")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AutoraTheme.muted)
                        Text(price.primary)
                            .font(.title2.weight(.bold).monospacedDigit())
                        Text(price.secondary)
                            .font(.caption)
                            .foregroundStyle(AutoraTheme.muted)
                        if let buy = car.buyPriceUSD {
                            Text("Куплено за \(PriceConverter.formatUSD(Double(buy)))")
                                .font(.caption2)
                                .foregroundStyle(AutoraTheme.muted)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(car.monthlyChangeUSD >= 0 ? "+$\(car.monthlyChangeUSD)" : "-$\(abs(car.monthlyChangeUSD))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(car.monthlyChangeUSD >= 0 ? AutoraTheme.emerald : AutoraTheme.bargainRed)
                        Text("за 30 дней")
                            .font(.caption2)
                            .foregroundStyle(AutoraTheme.muted)
                    }
                }
                .padding(12)
                .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack(spacing: 8) {
                    reminder("Техосмотр", car.nextMotDate)
                    reminder("Страховка", car.nextInsuranceDate)
                    reminder("Масло", "\(car.nextOilServiceKm.formatted()) км")
                }
                Button("Удалить из автопарка", role: .destructive, action: onDelete)
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .padding(16)
        }
        .background(AutoraTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AutoraTheme.hairline, lineWidth: 1)
        }
    }

    private func reminder(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AutoraTheme.muted)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DeferredTrackerCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    let listing: Listing
    var onOpen: () -> Void
    @State private var editingNote = false
    @State private var noteDraft = ""
    @State private var editingTarget = false
    @State private var targetDraft = 0

    private var item: DeferredPurchase? { model.deferredPurchase(id: listing.id) }
    private var price: PriceDisplay.Pair {
        PriceDisplay.pair(byn: listing.priceBYN, rate: model.fx.usdBYN, showUSD: model.showUSD)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpen) {
                header
            }
            .buttonStyle(.plain)
            priceBlock
            targetBlock
            leaseLine
            noteBlock
            HStack {
                Button("Позвонить") {
                    if let url = PhoneLink.telURL(listing.sellerPhone) {
                        model.recordPhoneReveal(listingID: listing.id)
                        openURL(url)
                    } else {
                        model.flash("Связь с продавцом: \(listing.sellerPhone)")
                    }
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button("Убрать") { model.toggleDeferred(listing.id) }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AutoraTheme.bargainRed)
                    .padding(.horizontal, 12)
            }
        }
        .padding(16)
        .background(AutoraTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AutoraTheme.hairline, lineWidth: 1)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = listing.photoURLs.first {
                AutoraRemotePhoto(urlString: url, height: 140)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if let item, item.usdDropped(currentBYN: listing.priceBYN, usdBYN: model.fx.usdBYN) > 0 {
                            Text("−\(PriceConverter.formatUSD(Double(item.usdDropped(currentBYN: listing.priceBYN, usdBYN: model.fx.usdBYN)))) от старта")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(AutoraTheme.bargainRed, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .padding(10)
                        }
                    }
            }
            Text(listing.title)
                .font(.headline)
                .foregroundStyle(AutoraTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(listing.year) г. • \(listing.mileageKm.formatted()) км • \(ListingSpecs.engineLine(listing))")
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
        }
    }

    private var priceBlock: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Текущая цена")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AutoraTheme.muted)
                Text(price.primary)
                    .font(.title2.weight(.bold).monospacedDigit())
                Text(price.secondary)
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
            }
            Spacer()
            if let item {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Было")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AutoraTheme.muted)
                    Text(
                        PriceDisplay.pair(
                            byn: item.originalPriceBYN,
                            rate: model.fx.usdBYN,
                            showUSD: model.showUSD
                        ).primary
                    )
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .strikethrough()
                    .foregroundStyle(AutoraTheme.muted)
                }
            }
        }
        .padding(12)
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var targetBlock: some View {
        if let item {
            let reached = item.isTargetReached(currentBYN: listing.priceBYN, usdBYN: model.fx.usdBYN)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Моя целевая цена", systemImage: "bell.fill")
                        .font(.caption.weight(.bold))
                    Spacer()
                    if editingTarget {
                        HStack {
                            TextField("USD", value: $targetDraft, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 72)
                            Button("OK") {
                                model.setDeferredTargetUSD(listing.id, targetDraft)
                                editingTarget = false
                            }
                            .font(.caption.weight(.bold))
                        }
                    } else {
                        Button {
                            targetDraft = item.targetPriceUSD
                            editingTarget = true
                        } label: {
                            Text(PriceConverter.formatUSD(Double(item.targetPriceUSD)))
                                .font(.caption.weight(.bold))
                        }
                    }
                }
                Text(
                    reached
                        ? "Целевая цена достигнута. Можно покупать."
                        : "До цели ещё \(PriceConverter.formatUSD(Double(item.usdToTarget(currentBYN: listing.priceBYN, usdBYN: model.fx.usdBYN))))"
                )
                .font(.caption)
                .foregroundStyle(reached ? AutoraTheme.emerald : AutoraTheme.ink)
            }
            .padding(12)
            .background(
                reached ? AutoraTheme.emerald.opacity(0.12) : AutoraTheme.amber.opacity(0.14),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }

    private var leaseLine: some View {
        let usd = PriceConverter.usd(fromBYN: listing.priceBYN, rate: model.fx.usdBYN)
        let monthly = LeaseQuote.monthlyBYN(priceUSD: usd, downPercent: 30, years: 4, usdBYN: model.fx.usdBYN)
        return HStack {
            Text("Лизинг 30% / 4 г.")
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
            Spacer()
            Text("\(monthly.formatted()) Br / мес")
                .font(.caption.weight(.bold))
        }
        .padding(12)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var noteBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Моя заметка")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AutoraTheme.muted)
                Spacer()
                Button(editingNote ? "Отмена" : "Изменить") {
                    if editingNote {
                        editingNote = false
                    } else {
                        noteDraft = item?.userNote ?? ""
                        editingNote = true
                    }
                }
                .font(.caption.weight(.semibold))
            }
            if editingNote {
                TextField("Договорились о встрече…", text: $noteDraft, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.footnote)
                Button("Сохранить") {
                    model.setDeferredNote(listing.id, noteDraft)
                    editingNote = false
                }
                .font(.caption.weight(.bold))
            } else {
                Text((item?.userNote.isEmpty == false) ? (item?.userNote ?? "") : "Добавьте заметку к авто.")
                    .font(.footnote)
                    .foregroundStyle(AutoraTheme.ink.opacity(0.8))
                    .italic()
            }
        }
    }
}

private struct AddGarageCarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var make = "Geely"
    @State private var modelName = ""
    @State private var year = 2022
    @State private var mileageKm = 40_000
    @State private var city = "Минск"
    @State private var licensePlate = ""
    @State private var buyPriceUSD = 0

    private var makes: [String] {
        let catalog = FilterCatalog.makes(in: model.listings)
        return catalog.isEmpty ? ["Geely", "BMW", "Volkswagen", "Toyota"] : catalog
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Марка", selection: $make) {
                    ForEach(makes, id: \.self) { Text($0).tag($0) }
                }
                TextField("Модель", text: $modelName)
                Stepper("Год \(year)", value: $year, in: 1990...2026)
                TextField("Пробег, км", value: $mileageKm, format: .number)
                    .keyboardType(.numberPad)
                TextField("Город", text: $city)
                TextField("Номер, например 7788 AB-7", text: $licensePlate)
                    .textInputAutocapitalization(.characters)
                TextField("Куплено за, $", value: $buyPriceUSD, format: .number)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("В автопарк")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") { add() }
                        .disabled(modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func add() {
        let trimmed = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let quote = MarketValuation.quote(
            make: make,
            year: year,
            mileageKm: mileageKm,
            condition: .good,
            usdBYN: model.fx.usdBYN
        )
        model.addOwned(
            OwnedGarageCar(
                id: UUID().uuidString,
                make: make,
                model: trimmed,
                year: year,
                currentValueUSD: quote.usd,
                currentValueBYN: quote.byn,
                monthlyChangeUSD: 0,
                mileageKm: mileageKm,
                nextMotDate: "—",
                nextInsuranceDate: "—",
                nextOilServiceKm: mileageKm + 10_000,
                city: city,
                engine: "—",
                photoURL: nil,
                licensePlate: licensePlate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : licensePlate.trimmingCharacters(in: .whitespacesAndNewlines),
                buyPriceUSD: buyPriceUSD > 0 ? buyPriceUSD : nil
            )
        )
        dismiss()
    }
}
