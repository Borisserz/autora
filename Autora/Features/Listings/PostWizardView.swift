import SwiftUI
import PhotosUI
import UIKit

struct PostWizardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var picked: [PhotosPickerItem] = []
    @State private var error: String?
    @State private var showCamera = false
    @State private var listingID = "mine-\(UUID().uuidString.prefix(8))"

    private let stepCount = 6

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Шаг \(step + 1) из \(stepCount)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(AutoraTheme.muted)
                    .accessibilityIdentifier("autora.wizard.step")
                ProgressView(value: Double(step + 1), total: Double(stepCount))
                    .tint(AutoraTheme.ink)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AutoraTheme.ink)
                Group {
                    switch step {
                    case 0: photosStep
                    case 1:
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("VIN (необязательно)", text: vinBinding)
                                .textInputAutocapitalization(.characters)
                                .font(.body.monospacedDigit())
                            Text("\(ListingDraft.normalizedVIN(model.listingDraft.vin).count)/17 · пустой или 17 символов")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AutoraTheme.muted)
                        }
                    case 2:
                        ScrollView {
                            specStep
                        }
                    case 3:
                        priceStep
                    case 4: cityStep
                    default:
                        TextField("Описание", text: $model.listingDraft.description, axis: .vertical)
                            .lineLimit(4...8)
                    }
                }
                .padding()
                .background(AutoraTheme.canvas)
                .overlay {
                    RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous)
                        .stroke(AutoraTheme.hairline, lineWidth: 1)
                }
                if let error {
                    Text(error).foregroundStyle(AutoraTheme.danger)
                }
                Spacer()
                HStack(spacing: 12) {
                    Button("Назад") {
                        if step == 0 { dismiss() } else { step -= 1 }
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, 16)
                    .foregroundStyle(AutoraTheme.ink)
                    .background(AutoraTheme.canvas)
                    .overlay {
                        RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous)
                            .stroke(AutoraTheme.hairline, lineWidth: 1)
                    }
                    .buttonStyle(PressableInkStyle())
                    .accessibilityIdentifier("autora.wizard.back")
                    Button(step < 5 ? "Далее" : (model.editingListingID != nil ? "Сохранить" : "Опубликовать")) {
                        advance()
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, 16)
                    .foregroundStyle(step < 5 ? AutoraTheme.canvas : .black)
                    .background(canAdvance ? (step < 5 ? AutoraTheme.ink : AutoraTheme.emerald) : AutoraTheme.ink.opacity(0.35))
                    .buttonStyle(PressableInkStyle())
                    .accessibilityIdentifier(AutoraID.wizardNext)
                }
            }
            .padding(20)
            .paperCanvas()
            .navigationTitle(model.editingListingID != nil ? "Редактировать" : "Подать объявление")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { data in
                    appendPhoto(data)
                }
                .ignoresSafeArea()
            }
            .onAppear {
                if let id = model.editingListingID {
                    listingID = id
                }
            }
        }
    }

    private var title: String {
        ["Фото", "VIN", "Комплектация", "Оценка и цена", "Город", "Описание"][step]
    }

    private var canAdvance: Bool {
        step >= 5 || model.listingDraft.canLeave(step: step)
    }

    private var photosStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.listingDraft.photoURLs.isEmpty {
                Text("Добавьте свои кадры. Без фото дальше нельзя.")
                    .foregroundStyle(AutoraTheme.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(model.listingDraft.photoURLs.enumerated()), id: \.offset) { index, url in
                            VStack {
                                AutoraRemotePhoto(urlString: url, height: 96)
                                    .frame(width: 120, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                                HStack {
                                    Button("←") { movePhoto(index, by: -1) }
                                    Button("→") { movePhoto(index, by: 1) }
                                }
                                .font(.footnote)
                            }
                        }
                    }
                }
            }
            PhotosPicker(selection: $picked, maxSelectionCount: 10, matching: .images) {
                Text(model.listingDraft.photoURLs.isEmpty ? "Выбрать из галереи" : "Ещё из галереи")
                    .font(.body.weight(.semibold))
            }
            .onChange(of: picked) { _, items in
                Task { await importPicked(items) }
            }
            Button("Снять на камеру") { showCamera = true }
                .font(.body)
            if UITestLaunch.isActive {
                Button("Тестовое фото") { appendFixturePhoto() }
                    .font(.body.weight(.semibold))
                    .accessibilityIdentifier(AutoraID.wizardTestPhoto)
                Button("Тестовый черновик") { fillFixtureDraft() }
                    .font(.body)
                    .accessibilityIdentifier(AutoraID.wizardTestDraft)
            }
        }
        .foregroundStyle(AutoraTheme.ink)
    }

    private var specStep: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 12) {
            chipPick("Марка", options: FilterCatalog.makesForPost(in: model.listings), value: $model.listingDraft.make)
            chipPick(
                "Модель",
                options: FilterCatalog.modelsForPost(in: model.listings, make: model.listingDraft.make),
                value: $model.listingDraft.model,
                allowCustom: true
            )
            TextField("Модель, если нет в списке", text: $model.listingDraft.model)
            chipPick(
                "Поколение",
                options: FilterCatalog.generationsForPost(
                    in: model.listings,
                    make: model.listingDraft.make,
                    model: model.listingDraft.model
                ),
                value: $model.listingDraft.generation
            )
            chipPick("Кузов", options: FilterCatalog.bodiesForPost(in: model.listings), value: $model.listingDraft.body)
            chipPick("Топливо", options: FilterCatalog.fuels(in: model.listings), value: $model.listingDraft.fuel)
            chipPick("КПП", options: FilterCatalog.transmissions(in: model.listings), value: $model.listingDraft.transmission)
            chipPick("Привод", options: FilterCatalog.drivetrains(in: model.listings), value: $model.listingDraft.drivetrain)
            Stepper("Год \(model.listingDraft.year)", value: $model.listingDraft.year, in: 1990...2026)
            Stepper(
                String(format: "Объём %.1f л", model.listingDraft.engineLiters),
                value: $model.listingDraft.engineLiters,
                in: 0.6...6.0,
                step: 0.1
            )
            Stepper("Мощность \(model.listingDraft.powerHp) л.с.", value: $model.listingDraft.powerHp, in: 50...700, step: 5)
            TextField("Пробег, км", value: $model.listingDraft.mileageKm, format: .number)
                .keyboardType(.numberPad)
                .font(.body.monospacedDigit())
            HStack(spacing: 6) {
                ForEach(ListingCondition.allCases, id: \.self) { item in
                    Button(item.title) { model.listingDraft.condition = item }
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(model.listingDraft.condition == item ? AutoraTheme.canvas : AutoraTheme.ink)
                        .background(
                            model.listingDraft.condition == item ? AutoraTheme.ink : AutoraTheme.surface,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .buttonStyle(PressableInkStyle())
                }
            }
            chipPick("Руль", options: ["левый", "правый"], value: wheelLabel)
            Toggle("На учёте в РБ", isOn: $model.listingDraft.registered)
            Toggle("Растаможен", isOn: $model.listingDraft.customsCleared)
            Toggle("Торг", isOn: $model.listingDraft.bargaining)
            Toggle("Обмен", isOn: $model.listingDraft.exchange)
            Text("Опции")
                .font(.footnote)
                .foregroundStyle(AutoraTheme.muted)
            ForEach(ListingSpecs.equipment, id: \.self) { item in
                Toggle(item, isOn: equipmentBinding(item))
            }
        }
        .onChange(of: model.listingDraft.make) { _, make in
            let models = FilterCatalog.modelsForPost(in: model.listings, make: make)
            if !models.contains(model.listingDraft.model) {
                model.listingDraft.model = ""
                model.listingDraft.generation = ""
            }
        }
        .onChange(of: model.listingDraft.model) { _, modelName in
            let gens = FilterCatalog.generationsForPost(
                in: model.listings,
                make: model.listingDraft.make,
                model: modelName
            )
            if !gens.contains(model.listingDraft.generation) {
                model.listingDraft.generation = ""
            }
        }
    }

    private var wheelLabel: Binding<String> {
        Binding(
            get: { model.listingDraft.wheel == .right ? "правый" : "левый" },
            set: { model.listingDraft.wheel = $0 == "правый" ? .right : .left }
        )
    }

    private var vinBinding: Binding<String> {
        Binding(
            get: { model.listingDraft.vin },
            set: { model.listingDraft.vin = String(ListingDraft.normalizedVIN($0).prefix(17)) }
        )
    }

    private func equipmentBinding(_ item: String) -> Binding<Bool> {
        Binding(
            get: { model.listingDraft.equipment.contains(item) },
            set: { isOn in
                if isOn {
                    if !model.listingDraft.equipment.contains(item) {
                        model.listingDraft.equipment.append(item)
                    }
                } else {
                    model.listingDraft.equipment.removeAll { $0 == item }
                }
            }
        )
    }

    private var priceStep: some View {
        @Bindable var model = model
        let quote = model.listingDraft.suggestedQuote(usdBYN: model.fx.usdBYN)
        let live = PriceDisplay.pair(byn: model.listingDraft.priceBYN, rate: model.fx.usdBYN, showUSD: model.showUSD)
        return VStack(alignment: .leading, spacing: 14) {
            TextField("Цена, Br", value: $model.listingDraft.priceBYN, format: .number)
                .keyboardType(.numberPad)
                .font(.title2.monospacedDigit().weight(.semibold))
            if model.listingDraft.priceBYN > 0 {
                Text("\(live.primary)  \(live.secondary)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AutoraTheme.ink)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Состояние для оценки")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AutoraTheme.muted)
                HStack(spacing: 6) {
                    ForEach(MarketValuation.Condition.allCases) { item in
                        Button(item.title) { model.listingDraft.valuationCondition = item }
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(model.listingDraft.valuationCondition == item ? AutoraTheme.canvas : AutoraTheme.ink)
                            .background(
                                model.listingDraft.valuationCondition == item ? AutoraTheme.ink : AutoraTheme.surface,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .buttonStyle(PressableInkStyle())
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Оценка CoolAV")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AutoraTheme.muted)
                Text("\(PriceConverter.formatUSD(Double(quote.usd)))  \(PriceConverter.formatApproxBYN(quote.byn))")
                    .font(.body.weight(.semibold))
                Text("Диапазон \(PriceConverter.formatUSD(Double(quote.minUSD)))–\(PriceConverter.formatUSD(Double(quote.maxUSD))) · продажа ~\(quote.days) дн.")
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
                Button("Подставить оценку") {
                    model.listingDraft.applySuggestedPrice(usdBYN: model.fx.usdBYN)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(12)
            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var cityStep: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 12) {
            chipPick("Город", options: FilterCatalog.citiesForPost(in: model.listings), value: $model.listingDraft.city)
            chipPick("Область", options: FilterCatalog.defaultRegions, value: $model.listingDraft.region)
        }
    }

    private func chipPick(_ title: String, options: [String], value: Binding<String>, allowCustom: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(AutoraTheme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options, id: \.self) { option in
                        Button(option) { value.wrappedValue = option }
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .foregroundStyle(value.wrappedValue == option ? AutoraTheme.canvas : AutoraTheme.ink)
                            .background(value.wrappedValue == option ? AutoraTheme.ink : Color.clear)
                            .overlay {
                                RoundedRectangle(cornerRadius: AutoraTheme.chipRadius, style: .continuous)
                                    .stroke(AutoraTheme.hairline, lineWidth: 1)
                            }
                    }
                }
            }
        }
    }

    private func advance() {
        error = nil
        if step < 5 {
            if let leaveError = model.listingDraft.leaveError(for: step) {
                error = leaveError.localizedDescription
                return
            }
            step += 1
        } else {
            publish()
        }
    }

    private func movePhoto(_ index: Int, by delta: Int) {
        let next = index + delta
        guard model.listingDraft.photoURLs.indices.contains(next) else { return }
        model.listingDraft.photoURLs.swapAt(index, next)
    }

    private func importPicked(_ items: [PhotosPickerItem]) async {
        for (offset, item) in items.enumerated() {
            guard let raw = try? await item.loadTransferable(type: Data.self) else { continue }
            appendPhoto(raw, index: model.listingDraft.photoURLs.count + offset)
        }
    }

    private func appendPhoto(_ raw: Data, index: Int? = nil) {
        guard let jpeg = ListingPhotoStore.jpegData(from: raw) else { return }
        let idx = index ?? model.listingDraft.photoURLs.count
        if let url = try? ListingPhotoStore.saveJPEG(jpeg, listingID: listingID, index: idx) {
            model.listingDraft.photoURLs.append(url.absoluteString)
        }
    }

    private func appendFixturePhoto() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 240))
        let data = renderer.jpegData(withCompressionQuality: 0.85) { _ in
            UIColor(white: 0.25, alpha: 1).setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 320, height: 240))
        }
        appendPhoto(data)
    }

    private func fillFixtureDraft() {
        if model.listingDraft.photoURLs.isEmpty {
            appendFixturePhoto()
        }
        model.listingDraft.make = "Mazda"
        model.listingDraft.model = "6"
        model.listingDraft.generation = "GJ"
        model.listingDraft.year = 2018
        model.listingDraft.priceBYN = 12000
        model.listingDraft.mileageKm = 80000
        model.listingDraft.body = "седан"
        model.listingDraft.fuel = "бензин"
        model.listingDraft.description = "UI-тест Autora"
    }

    private func publish() {
        error = nil
        guard let profile = model.session.profile else {
            error = AppError.needAuth.localizedDescription
            return
        }
        do {
            if model.editingListingID != nil {
                try model.saveEditedListing()
            } else {
                let listing = try model.listingDraft.makeListing(id: listingID, seller: profile, now: model.now())
                try model.publishDraft(listing)
                model.clearListingDraft()
            }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.85) {
                parent.onCapture(data)
            }
            parent.dismiss()
        }
    }
}
