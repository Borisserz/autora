import SwiftUI

struct CompareView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var pickerSlot: Int?
    @State private var showCatalog = false

    private var listings: [Listing] {
        model.compareIDs.compactMap(model.listing(id:))
    }

    private var pair: (Listing, Listing)? {
        guard listings.count >= 2 else { return nil }
        return (listings[0], listings[1])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Два объявления рядом: цена, пробег и срок продажи.")
                    .font(.footnote)
                    .foregroundStyle(AutoraTheme.muted)
                HStack(alignment: .top, spacing: 10) {
                    slot(0)
                    slot(1)
                }
                if let pair {
                    let delta = CompareDelta.of(pair.0, pair.1, usdBYN: model.fx.usdBYN)
                    if delta.isDuplicate {
                        Text("В обоих слотах одно и то же авто. Выберите другое во втором слоте.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AutoraTheme.ink)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(AutoraTheme.amber.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    deltaStrip(delta)
                    specTable
                    Button("Каталог моделей CoolAV") { showCatalog = true }
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(16)
        }
        .paperCanvas()
        .navigationTitle("Сравнение")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") { dismiss() }
            }
            if !listings.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Очистить") { model.clearCompare() }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { pickerSlot != nil },
            set: { if !$0 { pickerSlot = nil } }
        )) {
            ComparePickerView(slot: pickerSlot ?? 0)
        }
        .sheet(isPresented: $showCatalog) {
            ModelCatalogView()
        }
    }

    @ViewBuilder
    private func slot(_ index: Int) -> some View {
        if let listing = listing(at: index) {
            compareCard(listing, slot: index)
        } else {
            emptySlot(index)
        }
    }

    private func listing(at index: Int) -> Listing? {
        guard model.compareIDs.indices.contains(index) else { return nil }
        return model.listing(id: model.compareIDs[index])
    }

    private func emptySlot(_ index: Int) -> some View {
        Button {
            pickerSlot = index
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                Text("Авто \(index + 1)")
                    .font(.subheadline.weight(.semibold))
                Text("Подобрать из каталога")
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .foregroundStyle(AutoraTheme.ink)
            .background(AutoraTheme.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AutoraTheme.hairline, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            }
        }
        .buttonStyle(.plain)
    }

    private func compareCard(_ listing: Listing, slot: Int) -> some View {
        let price = PriceDisplay.pair(byn: listing.priceBYN, rate: model.fx.usdBYN, showUSD: model.showUSD)
        return VStack(alignment: .leading, spacing: 8) {
            if let url = listing.photoURLs.first {
                AutoraRemotePhoto(urlString: url, height: 110)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Text(listing.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
                .lineLimit(2)
            Text(price.primary)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(highlight(CompareAxis.cheaper(listings), listing.id))
            Text(price.secondary)
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
            Label("VIN: без ДТП", systemImage: "checkmark.shield.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AutoraTheme.emerald)
            Text("Продажа ~\(ListingLiquidity.daysToSell(listing, usdBYN: model.fx.usdBYN)) дн.")
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
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
            .padding(.vertical, 8)
            .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            HStack {
                Button("Заменить") { pickerSlot = slot }
                    .font(.caption.weight(.semibold))
                Button("Убрать") { model.toggleCompare(listing.id) }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AutoraTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AutoraTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AutoraTheme.hairline, lineWidth: 1)
        }
    }

    private func deltaStrip(_ delta: CompareDelta) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Разница в цене: \(PriceConverter.formatUSD(Double(delta.priceUSD))) · \(delta.cheaperLabel)")
                .font(.caption.weight(.semibold))
            Text("Пробег: \(delta.mileageKm.formatted()) км • Возраст: \(delta.yearSummary)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var specTable: some View {
        VStack(spacing: 0) {
            specRow("Год", listings.map { "\($0.year)" }, winner: CompareAxis.newer(listings))
            specRow("Пробег", listings.map { "\($0.mileageKm.formatted()) км" }, winner: CompareAxis.fewerKm(listings))
            specRow("Кузов", listings.map(\.body), winner: nil)
            specRow("Топливо", listings.map(\.fuel), winner: nil)
            specRow("КПП", listings.map(\.transmission), winner: nil)
            specRow("Город", listings.map(\.city), winner: nil)
            specRow("Продажа", listings.map { "\(ListingLiquidity.daysToSell($0, usdBYN: model.fx.usdBYN)) дн." }, winner: nil)
            specRow("Оценка", listings.map { String(format: "%.1f", insight($0).overall) }, winner: nil)
            specRow("Запчасти", listings.map { String(format: "%.1f", insight($0).parts) }, winner: nil)
            specRow("Комфорт", listings.map { String(format: "%.1f", insight($0).comfort) }, winner: nil)
            specRow("Надёжность", listings.map { String(format: "%.1f", insight($0).reliability) }, winner: nil)
            specRow("Содержание", listings.map { "$\(insight($0).monthlyUSD)/мес" }, winner: nil)
        }
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func insight(_ listing: Listing) -> ModelInsight.Insight {
        ModelInsight.lookup(make: listing.make, model: listing.model)
    }

    private func specRow(_ title: String, _ values: [String], winner: String?) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
                .frame(width: 64, alignment: .leading)
            ForEach(Array(listings.prefix(2).enumerated()), id: \.element.id) { index, listing in
                if index < values.count {
                    Text(values[index])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(highlight(winner, listing.id))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
    }

    private func highlight(_ winnerID: String?, _ id: String) -> Color {
        winnerID == id ? AutoraTheme.emerald : AutoraTheme.ink
    }
}
