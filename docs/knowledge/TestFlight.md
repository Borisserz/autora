# TestFlight checklist

## Archive

1. Xcode 26+ · схема Autora · Any iOS Device
2. Signing team `LSCCP92LMG` · bundle `com.borisdev.Autora`
3. Product → Archive → Distribute TestFlight

## Перед Archive

- [ ] `xcodebuild test` зелёный
- [ ] Симулятор: лента из seed.json, карточка, зум фото, избранное без логина
- [ ] Войти (демо) → подать объявление → чат
- [ ] USD тумблер в профиле
- [ ] App Icon 1024
- [ ] URL scheme `autora://listing/{id}`

## Firebase (не блокер визуала)

- [ ] Console Add iOS app
- [ ] `GoogleService-Info.plist` в target Autora
- [ ] Merge `firebase/firestore.autora.snippet.rules`
- [ ] `OWNER_UIDS` + named functions deploy
- [ ] Не включать App Check enforcement

## Crashlytics

После plist: dSYM upload в Release. Пока SDK не подключён — логи локально.
