import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var phone: String = ""
    @State private var name: String = ""
    @State private var showVIN = false
    @State private var showValuation = false
    @State private var showCompare = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(CoolAVCopy.wordmark)
                        .font(.system(.title, design: .serif))
                    Text("Инструменты")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AutoraTheme.muted)
                    toolButton("Проверка VIN", systemImage: "checkmark.shield.fill") { showVIN = true }
                    toolButton("AI Сравнение", systemImage: "scalemass.fill") { showCompare = true }
                    toolButton("Оценка авто", systemImage: "chart.line.uptrend.xyaxis") { showValuation = true }

                    Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
                    if case .signedIn(let profile) = model.session {
                        Text("Аккаунт")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AutoraTheme.muted)
                        TextField("Имя", text: $name)
                            .onAppear { name = profile.name; phone = profile.phone }
                            .padding(12)
                            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        TextField("Телефон", text: $phone)
                            .keyboardType(.phonePad)
                            .padding(12)
                            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Button("Сохранить") {
                            model.updateProfile(name: name, phone: phone)
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Button("Войти через Apple / Google (демо)") {
                            model.signInDemo()
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text("На TestFlight без plist Firebase это локальная сессия.")
                            .font(.footnote)
                            .foregroundStyle(AutoraTheme.muted)
                    }
                    Toggle("Показывать курс USD крупно (BYN всегда рядом)", isOn: Bindable(model).showUSD)
                    Text("Цена в данных — белорусские рубли. На экране CoolAV показывает $ крупно и Br справочно. Курс сида: \(model.fx.usdBYN, format: .number.precision(.fractionLength(2))).")
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.muted)
                    if model.session.isSignedIn {
                        Button("Выйти", role: .destructive, action: model.signOut)
                            .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .paperCanvas()
            .navigationTitle("Профиль")
            .sheet(isPresented: $showVIN) { VinCheckView() }
            .sheet(isPresented: $showValuation) { ValuationView() }
            .sheet(isPresented: $showCompare) {
                NavigationStack { CompareView() }
            }
        }
    }

    private func toolButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(AutoraTheme.amber)
                Text(title)
                    .font(.body.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
            }
            .foregroundStyle(AutoraTheme.ink)
            .padding(14)
            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableInkStyle())
    }
}
