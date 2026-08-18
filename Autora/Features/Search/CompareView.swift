import SwiftUI

struct CompareView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private var listings: [Listing] {
        model.compareIDs.compactMap(model.listing(id:))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Два автомобиля рядом. Выберите слот — видно цену и пробег.")
                    .font(.footnote)
                    .foregroundStyle(AutoraTheme.muted)
                HStack(alignment: .top, spacing: 10) {
                    slot(0)
                    slot(1)
                }
                if listings.count > 2 {
                    ForEach(listings.dropFirst(2)) { listing in
                        compareCard(listing, slot: 2)
                    }
                }
                if listings.count >= 2 {
                    specTable
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

    private func pickerListings(for index: Int) -> [Listing] {
        let taken = Set(
            model.compareIDs.enumerated().compactMap { offset, id in
                offset == index ? nil : id
            }
        )
        return model.listings.filter { $0.status == .active && !taken.contains($0.id) }
    }

    private func emptySlot(_ index: Int) -> some View {
        Menu {
            ForEach(pickerListings(for: index)) { listing in
                Button(listing.title) {
                    model.setCompare(listing.id, slot: index)
                }
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                Text("Авто \(index + 1)")
                    .font(.subheadline.weight(.semibold))
                Text("Выбрать из каталога")
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
            HStack {
                Menu("Заменить") {
                    ForEach(pickerListings(for: slot)) { candidate in
                        Button(candidate.title) {
                            model.setCompare(candidate.id, slot: slot)
                        }
                    }
                }
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

    private var specTable: some View {
        VStack(spacing: 0) {
            specRow("Год", listings.map { "\($0.year)" }, winner: CompareAxis.newer(listings))
            specRow("Пробег", listings.map { "\($0.mileageKm.formatted()) км" }, winner: CompareAxis.fewerKm(listings))
            specRow("Кузов", listings.map(\.body), winner: nil)
            specRow("Топливо", listings.map(\.fuel), winner: nil)
            specRow("КПП", listings.map(\.transmission), winner: nil)
            specRow("Город", listings.map(\.city), winner: nil)
        }
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func specRow(_ title: String, _ values: [String], winner: String?) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
                .frame(width: 64, alignment: .leading)
            ForEach(Array(listings.enumerated()), id: \.element.id) { index, listing in
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
