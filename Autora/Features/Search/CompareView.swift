import SwiftUI

struct CompareView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private var listings: [Listing] {
        model.compareIDs.compactMap(model.listing(id:))
    }

    var body: some View {
        Group {
            if listings.isEmpty {
                EmptyStateView(
                    title: "Нечего сравнивать",
                    text: "На карточке нажмите весы — до трёх машин. Лучше две: так видно выгоду.",
                    illustration: .search,
                    actionTitle: nil
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 10) {
                            ForEach(listings.prefix(2)) { listing in
                                compareCard(listing)
                            }
                        }
                        if listings.count > 2 {
                            ForEach(listings.dropFirst(2)) { listing in
                                compareCard(listing)
                            }
                        }
                        specTable
                    }
                    .padding(16)
                }
            }
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

    private func compareCard(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
            Text(PriceConverter.formatUSD(PriceConverter.usd(fromBYN: listing.priceBYN, rate: model.fx.usdBYN)))
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(highlight(CompareAxis.cheaper(listings), listing.id))
            Text(PriceConverter.formatApproxBYN(listing.priceBYN))
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
            Button("Убрать") { model.toggleCompare(listing.id) }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AutoraTheme.muted)
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
