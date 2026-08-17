# Firebase Autora

Проект `serzhanovich-ecosystem-ce700`, codebase `autora`.

1. Console → Add app → iOS → `com.borisdev.Autora`
2. Скачать `GoogleService-Info.plist` в папку `Autora/`
3. Вклеить `firestore.autora.snippet.rules` в канонические rules (не деплоить этот файл соло)
4. `OWNER_UIDS` secret
5. Деплой только:

```
cd firebase
npx -y firebase-tools@latest deploy --only functions:autoraSeedDemo,functions:autoraWipeDemo,functions:autoraOnListingWrite,functions:autoraNotifySavedSearch
```
