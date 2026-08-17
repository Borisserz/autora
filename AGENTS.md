# AGENTS.md — контракт проекта Autora

Главный паспорт для любой ИИ-сессии. Читать в начале работы.

## 1. Проект

* **Название:** Autora
* **Назначение:** iOS-маркетплейс легковых авто в Беларуси (покупатель + продавец). Конкурент av.by по потокам, не по бренду.
* **Стек:** SwiftUI, Swift 6, iOS 18.6+, Firebase (`serzhanovich-ecosystem-ce700`), Cloud Functions codebase `autora`
* **Bundle:** `com.borisdev.Autora` · Team `LSCCP92LMG`

### Память

| Путь | Зачем |
| :--- | :--- |
| `AGENTS.md` | Этот контракт |
| `.mcp.json` | MCP: codebase-memory, obsidian, chrome-devtools, code-review-graph, hyperresearch |
| `docs/knowledge/` | Vault: Architecture, Firebase-Safety, UI-Design, Avby-* |
| `docs/adr/` | Решения |
| `.agents/knowledge/` | KI подсистем |
| `.agents/skills/README.md` | Скиллы живут в `~/.cursor/skills/` |
| `agents/` | Роли |
| `PAPERCUTS.md` | Трение |

## 2. Три уровня памяти

1. Рабочий контекст (чат, rules)
2. Граф кода (codebase-memory-mcp) — после индексации
3. Долгосрочная: ADR, KI, docs/knowledge

Перед крупной правкой: `docs/adr/` + релевантная KI.

## 3. Команды

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Autora.xcodeproj -scheme Autora -destination 'platform=iOS Simulator,name=iPhone 17' test
xcodebuild -project Autora.xcodeproj -scheme Autora -destination 'generic/platform=iOS Simulator' build
```

Functions (только именами):

```
npx -y firebase-tools@latest deploy --only functions:autoraSeedDemo,functions:autoraWipeDemo,functions:autoraOnListingWrite,functions:autoraNotifySavedSearch
```

Никогда: `firebase deploy`, `deploy --only functions` без имён, деплой чужих rules.

## 4. Superpowers

brainstorming → spec → writing-plans → TDD → verification-before-completion. Не рапортовать «готово» без `xcodebuild test` / build.

## 5. Правила

1. Ответы агента — на русском, если пользователь не просил иное. Код UI — русский. Тесты — английские имена.
2. Не выдумывать пути: сначала glob/read.
3. Коллекции только `autora_*`. Storage `autora/...`.
4. Не удалять Firebase Auth UID (общий с Yoga/Workout/Food/Wardrobe).
5. Не парсить av.by. Сверка потоков — `docs/knowledge/Avby-Flows.md` и `docs/knowledge/avby-screens/`.
6. Цена в BYN; USD справочно.
7. Демо-документы: `isDemo: true`. Wipe только их.
8. PAPERCUTS — фоном при трении.

## 6. Старт сессии

1. Прочитать этот файл
2. `.agents/knowledge/`
3. `docs/adr/`
4. Нужный скилл из `~/.cursor/skills/`
