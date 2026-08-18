import SwiftUI

struct GarageView: View {
    @Environment(AppModel.self) private var model
    @State private var tab = 0
    @State private var path = NavigationPath()
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
        listingStack(
            model.listings.filter { model.isDeferred($0.id) },
            emptyTitle: "Ваш список отложенных покупок пуст",
            emptyText: "Нажимайте «В гараж» на автомобилях в каталоге, чтобы следить за скидками.",
            showsDrop: true
        )
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
                Text("Автомобили в вашей собственности")
                    .font(.system(.title3, design: .serif))
                ForEach(model.ownedGarage) { car in
                    GarageFleetCard(car: car)
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
    let car: OwnedGarageCar

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
                }
                .padding(12)
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
                        Text(PriceConverter.formatUSD(Double(car.currentValueUSD)))
                            .font(.title2.weight(.bold).monospacedDigit())
                        Text(PriceConverter.formatApproxBYN(car.currentValueBYN))
                            .font(.caption)
                            .foregroundStyle(AutoraTheme.muted)
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
