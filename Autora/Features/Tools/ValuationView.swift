import SwiftUI

struct ValuationView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var make = "Geely"
    @State private var year = 2022
    @State private var mileage = 45_000
    @State private var condition: MarketValuation.Condition = .good
    @State private var showRadar = false
    @State private var showCatalog = false

    private var quote: MarketValuation.Quote {
        MarketValuation.quote(
            make: make,
            year: year,
            mileageKm: mileage,
            condition: condition,
            usdBYN: model.fx.usdBYN
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Узнайте реальную рыночную стоимость авто")
                        .font(.system(.title2, design: .serif))
                    Text("Оценка для продажи и покупки. Курс сида CoolAV, не оферта.")
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.muted)

                    picker("Марка авто", selection: $make, options: ModelInsight.makes)
                    HStack {
                        stepper("Год", value: $year, range: 2015...2026)
                        stepper("Пробег, км", value: $mileage, range: 0...300_000, step: 5_000)
                    }
                    HStack {
                        ForEach(MarketValuation.Condition.allCases) { item in
                            Button(item.title) { condition = item }
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(condition == item ? .white : AutoraTheme.ink)
                                .background(
                                    condition == item ? AutoraTheme.ink : AutoraTheme.surface,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Рекомендованная рыночная цена")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AutoraTheme.muted)
                        Text(PriceConverter.formatUSD(Double(quote.usd)))
                            .font(.system(.largeTitle, design: .serif).weight(.bold))
                        Text(PriceConverter.formatApproxBYN(quote.byn))
                            .foregroundStyle(AutoraTheme.muted)
                        Text("Диапазон быстрой продажи: \(PriceConverter.formatUSD(Double(quote.minUSD))) — \(PriceConverter.formatUSD(Double(quote.maxUSD)))")
                            .font(.caption)
                            .foregroundStyle(AutoraTheme.muted)
                        Text("Прогнозируемый срок продажи: \(quote.days) дней")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AutoraTheme.emerald)
                        Text("Ликвидность модели: \(MarketValuation.liquidityTitle(days: quote.days))")
                            .font(.caption)
                            .foregroundStyle(AutoraTheme.muted)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button("Разместить объявление по этой цене") {
                        model.applyValuationToDraft(
                            make: make,
                            year: year,
                            mileageKm: mileage,
                            priceBYN: quote.byn
                        )
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button("Радар выгодных цен") { showRadar = true }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button("Каталог моделей") { showCatalog = true }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if let insight = ModelInsight.typical(forMake: make) {
                        Text("Типовая модель каталога — не оценка конкретного объявления.")
                            .font(.caption)
                            .foregroundStyle(AutoraTheme.muted)
                        ModelInsightCard(insight: insight)
                    }
                }
                .padding(20)
            }
            .paperCanvas()
            .navigationTitle("Оценка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .sheet(isPresented: $showRadar) {
                MarketRadarView()
            }
            .sheet(isPresented: $showCatalog) {
                ModelCatalogView(initialID: ModelInsight.typical(forMake: make)?.id)
            }
        }
    }

    private func picker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(AutoraTheme.muted)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func stepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(AutoraTheme.muted)
            Stepper(value: value, in: range, step: step) {
                Text("\(value.wrappedValue.formatted())")
                    .font(.body.monospacedDigit())
            }
            .padding(10)
            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct MarketRadarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    private var deals: [Listing] { MarketDeal.radar(in: model.listings) }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
            if deals.isEmpty {
                EmptyStateView(
                    title: "Пока нет явных выгод",
                    text: "Радар смотрит объявления ниже средней цены по марке и модели.",
                    illustration: .search,
                    actionTitle: nil
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(deals) { listing in
                            Button {
                                path.append(listing.id)
                            } label: {
                                radarRow(listing)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .paperCanvas()
        .navigationTitle("Радар выгод")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: String.self) { id in
            if let listing = model.listing(id: id) {
                ListingDetailView(listing: listing)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") { dismiss() }
            }
        }
        }
    }

    private func radarRow(_ listing: Listing) -> some View {
        let price = PriceDisplay.pair(byn: listing.priceBYN, rate: model.fx.usdBYN, showUSD: model.showUSD)
        let percent = MarketDeal.discountPercent(for: listing, in: model.listings) ?? 0
        let avg = MarketPrice.peerAverageBYN(for: listing, in: model.listings) ?? listing.priceBYN
        let avgPair = PriceDisplay.pair(byn: avg, rate: model.fx.usdBYN, showUSD: model.showUSD)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("−\(percent)% ниже рынка")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AutoraTheme.emerald)
                Spacer()
                Text(listing.city)
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
            }
            Text(listing.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
            HStack(alignment: .firstTextBaseline) {
                Text(price.primary)
                    .font(.title3.weight(.bold).monospacedDigit())
                Text(avgPair.primary)
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(AutoraTheme.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
