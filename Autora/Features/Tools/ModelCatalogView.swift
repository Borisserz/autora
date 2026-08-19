import SwiftUI

struct ModelCatalogView: View {
    @Environment(\.dismiss) private var dismiss
    var initialID: String?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    Text("8 моделей CoolAV: ликвидность, запчасти, плюсы и слабые места на рынке РБ.")
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(ModelInsight.catalog) { insight in
                        NavigationLink(value: insight.id) {
                            ModelCatalogRow(insight: insight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .paperCanvas()
            .navigationTitle("Каталог моделей")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { id in
                if let insight = ModelInsight.catalog.first(where: { $0.id == id }) {
                    ModelInsightDetailView(insight: insight)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .onAppear {
                if let initialID, path.isEmpty, ModelInsight.catalog.contains(where: { $0.id == initialID }) {
                    path.append(initialID)
                }
            }
        }
    }
}

private struct ModelCatalogRow: View {
    let insight: ModelInsight.Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.tag)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AutoraTheme.amber)
                Spacer()
                Text(String(format: "%.1f", insight.overall))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(AutoraTheme.ink)
            }
            Text("\(insight.make) \(insight.year)")
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
            Text(insight.model)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text(insight.priceRange)
                Spacer()
                Text("~\(insight.liquidityDays) дн. · $\(insight.monthlyUSD)/мес")
            }
            .font(.caption)
            .foregroundStyle(AutoraTheme.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct ModelInsightDetailView: View {
    let insight: ModelInsight.Insight
    var onDark: Bool = false

    var body: some View {
        ScrollView {
            ModelInsightCard(insight: insight, onDark: onDark)
                .padding(20)
        }
        .paperCanvas()
        .navigationTitle(insight.make)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelInsightCard: View {
    let insight: ModelInsight.Insight
    var onDark: Bool = false

    private var ink: Color { onDark ? .white : AutoraTheme.ink }
    private var muted: Color { onDark ? .white.opacity(0.72) : AutoraTheme.muted }
    private var fill: Color { onDark ? Color.white.opacity(0.06) : AutoraTheme.surface }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(insight.tag)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AutoraTheme.amber)
                Spacer()
                Text(String(format: "%.1f / 10", insight.overall))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(ink)
            }
            if !insight.model.isEmpty {
                Text(insight.model)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Содержание ~$\(insight.monthlyUSD) в месяц · продажа ~\(insight.liquidityDays) дн.")
                .font(.caption)
                .foregroundStyle(muted)
            if insight.avgPriceUSD > 0 {
                Text("Средняя \(insight.priceRange) · −\(insight.depreciationPerYear, format: .number.precision(.fractionLength(1)))% в год")
                    .font(.caption)
                    .foregroundStyle(muted)
            }

            scoreRow("Запчасти в РБ", insight.parts)
            scoreRow("Комфорт", insight.comfort)
            scoreRow("Надёжность", insight.reliability)

            if !insight.fuelType.isEmpty, insight.fuelType != "—" {
                Text("\(insight.fuelType) · \(insight.fuelConsumption)")
                    .font(.caption)
                    .foregroundStyle(muted)
                if insight.trunkVolumeL > 0 {
                    Text("Багажник \(insight.trunkVolumeL) л · 0–100 за \(insight.acceleration0100, format: .number.precision(.fractionLength(1))) с")
                        .font(.caption)
                        .foregroundStyle(muted)
                }
            }

            if !insight.pros.isEmpty {
                bulletBlock("Плюсы", items: insight.pros, tint: AutoraTheme.emerald)
            }
            if !insight.cons.isEmpty {
                bulletBlock("Минусы", items: insight.cons, tint: AutoraTheme.bargainRed)
            }
            if !insight.idealFor.isEmpty {
                labeled("Кому подходит", insight.idealFor)
            }
            if !insight.weakSpots.isEmpty {
                labeled("Слабые места", insight.weakSpots)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func scoreRow(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(muted)
                Spacer()
                Text(String(format: "%.1f", value))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(ink)
            }
            ProgressView(value: value, total: 10)
                .tint(onDark ? AutoraTheme.emerald : AutoraTheme.ink)
                .accessibilityLabel("\(title): \(String(format: "%.1f", value)) из 10")
        }
    }

    private func bulletBlock(_ title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(ink)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                        .padding(.top, 5)
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func labeled(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(ink)
            Text(text)
                .font(.caption)
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
