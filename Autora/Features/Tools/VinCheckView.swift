import SwiftUI

struct VinCheckView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vin = "X7LLG1234PA987654"
    @State private var searching = false
    @State private var ready = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Проверка автомобиля по VIN")
                        .font(.system(.title2, design: .serif))
                    Text("История CoolAV и открытые базы ГАИ. Демо-отчёт, без парсинга чужих сайтов.")
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.muted)
                    HStack {
                        TextField("VIN", text: $vin)
                            .textInputAutocapitalization(.characters)
                            .font(.body.monospacedDigit())
                        Button("Проверить") {
                            searching = true
                            Task {
                                try? await Task.sleep(for: .milliseconds(600))
                                searching = false
                                ready = true
                            }
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(vin.count < 5 || searching)
                    }
                    .padding(12)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if ready {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Проверен, ДТП не найдено", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(AutoraTheme.emerald)
                                .font(.subheadline.weight(.semibold))
                            Text("Юридическая чистота: ограничений не обнаружено.")
                                .font(.footnote)
                                .foregroundStyle(AutoraTheme.muted)
                            Text("Пробег по сервисам согласован с объявлением.")
                                .font(.footnote)
                                .foregroundStyle(AutoraTheme.muted)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
            }
            .paperCanvas()
            .navigationTitle("VIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct ValuationView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var make = "Geely"
    @State private var year = 2022
    @State private var mileage = 45_000
    @State private var condition: MarketValuation.Condition = .good

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

                    picker("Марка авто", selection: $make, options: ["Geely", "BMW", "Volkswagen", "Tesla", "Mercedes-Benz", "Toyota", "Li Auto"])
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
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button("Разместить объявление по этой цене") {
                        dismiss()
                        model.selectedTab = .listings
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
