import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var phone: String = ""
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if case .signedIn(let profile) = model.session {
                        sectionTitle("Аккаунт")
                        TextField("Имя", text: $name)
                            .onAppear { name = profile.name; phone = profile.phone }
                        fieldChrome
                        TextField("Телефон", text: $phone)
                            .keyboardType(.phonePad)
                        fieldChrome
                        Button("Сохранить") {
                            model.updateProfile(name: name, phone: phone)
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AutoraTheme.ink)
                    } else {
                        Button("Войти через Apple / Google (демо)") {
                            model.signInDemo()
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AutoraTheme.ink)
                        Text("На TestFlight без plist Firebase это локальная сессия. После Add iOS app в Console подключится настоящий Auth.")
                            .font(.footnote)
                            .foregroundStyle(AutoraTheme.muted)
                    }
                    Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
                    sectionTitle("Отображение")
                    Toggle("Показывать цену в USD справочно", isOn: Bindable(model).showUSD)
                    Text("Курс НБРБ в сидах: \(model.fx.usdBYN, format: .number.precision(.fractionLength(2))). Основная цена — белорусские рубли. USD — справочно, не оферта.")
                        .font(.footnote)
                        .foregroundStyle(AutoraTheme.muted)
                    if model.session.profile?.isOwner == true {
                        Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
                        sectionTitle("Демо")
                        Text("Залить / снести демо на сервере — Cloud Functions autoraSeedDemo / autoraWipeDemo после деплоя codebase autora. Сейчас лента из seed.json.")
                            .font(.footnote)
                            .foregroundStyle(AutoraTheme.muted)
                    }
                    if model.session.isSignedIn {
                        Button("Выйти", role: .destructive, action: model.signOut)
                            .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .paperCanvas()
            .navigationTitle("Профиль")
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(AutoraTheme.muted)
    }

    private var fieldChrome: some View {
        Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
    }
}
