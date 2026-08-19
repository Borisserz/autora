import SwiftUI

struct VinCheckView: View {
    @Environment(\.dismiss) private var dismiss
    var initialVin: String = ""
    @State private var vin: String
    @State private var searching = false
    @State private var ready = false

    init(initialVin: String = "") {
        self.initialVin = initialVin
        _vin = State(initialValue: String(initialVin.prefix(17)))
    }

    private var report: VinReport { VinReport.demo(vin: vin) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Проверка автомобиля по VIN")
                        .font(.title2.weight(.semibold))
                    Text(CoolAVCopy.vinLead)
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.muted)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            TextField("VIN", text: $vin)
                                .textInputAutocapitalization(.characters)
                                .font(.body.monospacedDigit())
                                .onChange(of: vin) { _, value in
                                    let clipped = String(value.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(17))
                                    if clipped != vin { vin = clipped }
                                }
                            Text("\(vin.count)/17")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AutoraTheme.muted)
                            Button(searching ? "Поиск…" : "Проверить") {
                                searching = true
                                ready = false
                                Task {
                                    try? await Task.sleep(for: .milliseconds(600))
                                    searching = false
                                    ready = true
                                }
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AutoraTheme.canvas)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .disabled(vin.count < 5 || searching)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Text("Примеры")
                                    .font(.caption)
                                    .foregroundStyle(AutoraTheme.muted)
                                ForEach(VinReport.samples) { sample in
                                    Button(sample.label) {
                                        vin = sample.vin
                                        ready = false
                                    }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 44)
                                    .background(AutoraTheme.canvas, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if ready {
                        reportBlock
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

    private var reportBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Демо-отчёт: шаблон «чист» для любого VIN")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AutoraTheme.ink)
                    Text("Не база ГАИ. VIN: \(report.vin)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AutoraTheme.muted)
                }
                Spacer()
                Text("Рейтинг \(report.safetyScore.formatted(.number.precision(.fractionLength(1)))) / 10")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.white, in: Capsule())
            }
            .padding(14)
            .background(AutoraTheme.amber.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statusCell("Розыск (ГАИ РБ)", report.wantedOK ? "Не числится" : "Проверить")
                statusCell("Залоги в банках", report.liensOK ? "Без обременений" : "Проверить")
                statusCell("История ДТП", report.accidentsOK ? "Не зафиксировано" : "Проверить")
                statusCell("Владельцев в РБ", "\(report.ownersInBY) владелец")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("История пробега")
                    .font(.subheadline.weight(.bold))
                ForEach(report.mileage) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(event.date) • \(event.title)")
                                .font(.caption)
                            Text("\(event.km.formatted()) км")
                                .font(.caption.weight(.bold).monospacedDigit())
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Регистрационные действия")
                    .font(.subheadline.weight(.bold))
                ForEach(report.registry) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.caption.weight(.semibold))
                        Text(event.detail)
                            .font(.caption)
                            .foregroundStyle(AutoraTheme.muted)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func statusCell(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(AutoraTheme.muted)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AutoraTheme.emerald)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
