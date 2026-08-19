import SwiftUI

struct FiltersSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    chipSection("Марка", options: FilterCatalog.makes(in: model.listings), value: Bindable(model).criteria.make, anyLabel: "Любая")
                    chipSection("Модель", options: FilterCatalog.models(in: model.listings, make: model.criteria.make), value: Bindable(model).criteria.model, anyLabel: "Любая")
                    chipSection(
                        "Поколение",
                        options: FilterCatalog.generations(in: model.listings, make: model.criteria.make, model: model.criteria.model),
                        value: Bindable(model).criteria.generation,
                        anyLabel: "Любое"
                    )
                    sliders
                    conditionChips
                    extraFlags
                    chipSection("Область", options: FilterCatalog.regions(in: model.listings), value: Bindable(model).criteria.region, anyLabel: "Любая")
                    chipSection("Город", options: FilterCatalog.cities(in: model.listings), value: Bindable(model).criteria.city, anyLabel: "Любой")
                    chipSection("Кузов", options: FilterCatalog.bodies(in: model.listings), value: Bindable(model).criteria.body, anyLabel: "Любой")
                    chipSection("Топливо", options: FilterCatalog.fuels(in: model.listings), value: Bindable(model).criteria.fuel, anyLabel: "Любое")
                    chipSection("КПП", options: FilterCatalog.transmissions(in: model.listings), value: Bindable(model).criteria.transmission, anyLabel: "Любая")
                    chipSection("Привод", options: FilterCatalog.drivetrains(in: model.listings), value: Bindable(model).criteria.drivetrain, anyLabel: "Любой")
                    flags
                }
                .padding(20)
            }
            .paperCanvas()
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: model.criteria.make) { _, newMake in
                let models = FilterCatalog.models(in: model.listings, make: newMake)
                if let current = model.criteria.model, !models.contains(current) {
                    model.criteria.model = nil
                    model.criteria.generation = nil
                }
            }
            .onChange(of: model.criteria.model) { _, newModel in
                let gens = FilterCatalog.generations(in: model.listings, make: model.criteria.make, model: newModel)
                if let current = model.criteria.generation, !gens.contains(current) {
                    model.criteria.generation = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Сбросить") { model.criteria = SearchCriteria() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Показать \(model.filtered.count)") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var sliders: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Год и цена")
                .font(.footnote)
                .foregroundStyle(AutoraTheme.muted)
            labeledSlider(
                title: "Год от \(model.criteria.yearFrom.map(String.init) ?? "любой")",
                range: 1990...2026,
                value: Bindable(model).criteria.yearFrom,
                step: 1
            )
            labeledSlider(
                title: "Год до \(model.criteria.yearTo.map(String.init) ?? "любой")",
                range: 1990...2026,
                value: Bindable(model).criteria.yearTo,
                step: 1
            )
            labeledSlider(
                title: priceFromTitle,
                range: priceToRange,
                value: priceFromBinding,
                step: model.showUSD ? 100 : 500
            )
            labeledSlider(
                title: priceToTitle,
                range: priceToRange,
                value: priceToBinding,
                step: model.showUSD ? 100 : 500
            )
            compactField("Пробег до, км", value: Bindable(model).criteria.mileageTo)
            compactField("Объём от, л×10", value: engineBinding)
            compactField("Мощность от, л.с.", value: Bindable(model).criteria.powerFrom)
        }
    }

    private var priceFromTitle: String {
        guard let price = model.criteria.priceFrom else { return "Цена от любая" }
        if model.showUSD {
            let usd = PriceConverter.filterUSD(fromBYN: price, rate: model.fx.usdBYN)
            return "Цена от $\(usd.formatted()) справочно"
        }
        return "Цена от \(price.formatted()) Br"
    }

    private var priceToTitle: String {
        guard let price = model.criteria.priceTo else { return "Цена до любая" }
        if model.showUSD {
            let usd = PriceConverter.filterUSD(fromBYN: price, rate: model.fx.usdBYN)
            return "Цена до $\(usd.formatted()) справочно"
        }
        return "Цена до \(price.formatted()) Br"
    }

    private var priceToRange: ClosedRange<Int> {
        model.showUSD ? 300...27_000 : 1_000...80_000
    }

    private var priceFromBinding: Binding<Int?> {
        Binding(
            get: {
                guard let byn = model.criteria.priceFrom else { return nil }
                if model.showUSD {
                    return PriceConverter.filterUSD(fromBYN: byn, rate: model.fx.usdBYN)
                }
                return byn
            },
            set: { newValue in
                guard let newValue else {
                    model.criteria.priceFrom = nil
                    return
                }
                if model.showUSD {
                    model.criteria.priceFrom = PriceConverter.byn(fromUSD: Double(newValue), rate: model.fx.usdBYN)
                } else {
                    model.criteria.priceFrom = newValue
                }
            }
        )
    }

    private var priceToBinding: Binding<Int?> {
        Binding(
            get: {
                guard let byn = model.criteria.priceTo else { return nil }
                if model.showUSD {
                    return PriceConverter.filterUSD(fromBYN: byn, rate: model.fx.usdBYN)
                }
                return byn
            },
            set: { newValue in
                guard let newValue else {
                    model.criteria.priceTo = nil
                    return
                }
                if model.showUSD {
                    model.criteria.priceTo = PriceConverter.byn(fromUSD: Double(newValue), rate: model.fx.usdBYN)
                } else {
                    model.criteria.priceTo = newValue
                }
            }
        )
    }

    private var conditionChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Состояние")
                .font(.footnote)
                .foregroundStyle(AutoraTheme.muted)
            FlowChips {
                filterChip("Любое", selected: model.criteria.condition == nil) {
                    model.criteria.condition = nil
                }
                ForEach(ListingCondition.allCases, id: \.self) { item in
                    filterChip(item.title, selected: model.criteria.condition == item) {
                        model.criteria.condition = model.criteria.condition == item ? nil : item
                    }
                }
            }
        }
    }

    private var extraFlags: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Документы и руль")
                .font(.footnote)
                .foregroundStyle(AutoraTheme.muted)
            FlowChips {
                optionalFlag("На учёте", value: Bindable(model).criteria.registered)
                optionalFlag("Растаможен", value: Bindable(model).criteria.customsCleared)
                filterChip("Левый руль", selected: model.criteria.wheel == .left) {
                    model.criteria.wheel = model.criteria.wheel == .left ? nil : .left
                }
                filterChip("Правый руль", selected: model.criteria.wheel == .right) {
                    model.criteria.wheel = model.criteria.wheel == .right ? nil : .right
                }
            }
        }
    }

    private var engineBinding: Binding<Int?> {
        Binding(
            get: { model.criteria.engineFrom.map { Int($0 * 10) } },
            set: { model.criteria.engineFrom = $0.map { Double($0) / 10 } }
        )
    }

    private func labeledSlider(title: String, range: ClosedRange<Int>, value: Binding<Int?>, step: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(AutoraTheme.ink)
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue ?? range.lowerBound) },
                    set: { value.wrappedValue = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(AutoraTheme.ink)
            Button("Сбросить") { value.wrappedValue = nil }
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
        }
    }

    private var flags: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Флаги")
                .font(.footnote)
                .foregroundStyle(AutoraTheme.muted)
            FlowChips {
                flagChip("Скрыть проданные", isOn: Bindable(model).criteria.hideSold)
                optionalFlag("С фото", value: Bindable(model).criteria.hasPhotos)
                optionalFlag("Торг", value: Bindable(model).criteria.bargaining)
                optionalFlag("Обмен", value: Bindable(model).criteria.exchange)
            }
        }
    }

    private func chipSection(_ title: String, options: [String], value: Binding<String?>, anyLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(AutoraTheme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    filterChip(anyLabel, selected: value.wrappedValue == nil) {
                        value.wrappedValue = nil
                    }
                    ForEach(options, id: \.self) { option in
                        filterChip(option, selected: value.wrappedValue == option) {
                            value.wrappedValue = option
                        }
                    }
                }
            }
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .foregroundStyle(selected ? AutoraTheme.canvas : AutoraTheme.ink)
            .background(selected ? AutoraTheme.ink : Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: AutoraTheme.chipRadius, style: .continuous)
                    .stroke(selected ? AutoraTheme.ink : AutoraTheme.hairline, lineWidth: 1)
            }
            .buttonStyle(PressableInkStyle())
    }

    private func compactField(_ title: String, value: Binding<Int?>) -> some View {
        TextField(title, value: value, format: .number)
            .keyboardType(.numberPad)
            .font(.body.monospacedDigit())
            .padding(10)
            .overlay {
                RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous)
                    .stroke(AutoraTheme.hairline, lineWidth: 1)
            }
    }

    private func flagChip(_ title: String, isOn: Binding<Bool>) -> some View {
        filterChip(title, selected: isOn.wrappedValue) {
            isOn.wrappedValue.toggle()
        }
    }

    private func optionalFlag(_ title: String, value: Binding<Bool?>) -> some View {
        filterChip(title, selected: value.wrappedValue == true) {
            value.wrappedValue = value.wrappedValue == true ? nil : true
        }
    }
}

private struct FlowChips<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            content
        }
    }
}
