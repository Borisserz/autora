import SwiftUI

struct ComparePickerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let slot: Int
    @State private var query = ""
    @State private var make: String?

    private var taken: Set<String> {
        Set(
            model.compareIDs.enumerated().compactMap { offset, id in
                offset == slot ? nil : id
            }
        )
    }

    private var results: [Listing] {
        model.listings.filter { listing in
            guard listing.status == .active, !taken.contains(listing.id) else { return false }
            if let make, listing.make != make { return false }
            let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !q.isEmpty else { return true }
            return listing.title.lowercased().contains(q)
                || listing.city.lowercased().contains(q)
                || listing.make.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Марка, модель или город", text: $query)
                    .padding(12)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("Все", selected: make == nil) { make = nil }
                        ForEach(FilterCatalog.makes(in: model.listings), id: \.self) { name in
                            chip(name, selected: make == name) {
                                make = make == name ? nil : name
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                List(results) { listing in
                    Button {
                        model.setCompare(listing.id, slot: slot)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AutoraTheme.ink)
                            Text("\(listing.year) • \(listing.city) • \(PriceDisplay.pair(byn: listing.priceBYN, rate: model.fx.usdBYN, showUSD: model.showUSD).primary)")
                                .font(.caption)
                                .foregroundStyle(AutoraTheme.muted)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .paperCanvas()
            .navigationTitle("Слот \(slot + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? .white : AutoraTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? AutoraTheme.ink : AutoraTheme.surface, in: Capsule())
    }
}
