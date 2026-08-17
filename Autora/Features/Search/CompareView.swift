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
                    text: "На карточке нажмите «Сравнить» — до трёх машин.",
                    illustration: .search,
                    actionTitle: nil
                )
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 0) {
                        GridRow {
                            Text("").frame(width: 96)
                            ForEach(listings) { listing in
                                compareHeader(listing)
                            }
                        }
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            Rectangle()
                                .fill(AutoraTheme.hairline)
                                .frame(height: 1)
                                .gridCellColumns(listings.count + 1)
                            GridRow {
                                Text(row.0)
                                    .font(.footnote)
                                    .foregroundStyle(AutoraTheme.muted)
                                    .frame(width: 96, alignment: .leading)
                                ForEach(listings) { listing in
                                    Text(row.1(listing))
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(AutoraTheme.ink)
                                        .frame(width: 140, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(20)
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

    private func compareHeader(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = listing.photoURLs.first {
                AutoraRemotePhoto(urlString: url, height: 88)
                    .frame(width: 140, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: AutoraTheme.photoRadius, style: .continuous))
            }
            Text(listing.title)
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)
            Button("Убрать", systemImage: "xmark") {
                model.toggleCompare(listing.id)
            }
            .font(.footnote)
            .foregroundStyle(AutoraTheme.muted)
        }
    }

    private var rows: [(String, (Listing) -> String)] {
        [
            ("Цена", { PriceConverter.formatBYN($0.priceBYN) }),
            ("Год", { "\($0.year)" }),
            ("Пробег", { "\($0.mileageKm.formatted()) км" }),
            ("Кузов", { $0.body }),
            ("Двигатель", { "\($0.engineLiters) л · \($0.powerHp) л.с." }),
            ("Топливо", { $0.fuel }),
            ("КПП", { $0.transmission }),
            ("Привод", { $0.drivetrain }),
            ("Город", { $0.city }),
            ("Руль", { $0.wheel == .left ? "Левый" : "Правый" }),
            ("Растаможен", { $0.customsCleared ? "Да" : "Нет" })
        ]
    }
}
