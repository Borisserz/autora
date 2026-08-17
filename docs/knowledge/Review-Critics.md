---
title: Review Critics
tags: [review, swiftui, hallmark, security]
date: 2026-08-17
---

# Review-Critics

Аудит 2026-08-17. Жанр: editorial catalog ([[UI-Design]]). Не av.by `#0084E6`, не фиолетовый градиент.

Связанные: [[UI-Design]] [[Firebase-Safety]] [[Avby-Flows]] [[Review-Personas]]

## MUST (этот раунд, cap 5)

1. **Токены и тёмная тема.** `AutoraTheme` только light; карточки и бейджи на `.white`. Dark из [[UI-Design]] не подключён. Карточка не clip'ает фото под radius 20 — выглядит как шаблон маркетплейса, не журнал.
2. **Фильтры — пикеры из сида.** `FiltersSheet` — свободный текст марки/кузова/города. Покупатель Passat не должен угадывать строку.
3. **Фото в подаче.** `PostWizardView` шаг 0: «фото в следующей сборке» + чужой Unsplash URL. Нужен `PhotosPicker`.
4. **Сравнение до 3.** `AppModel.compareIDs` есть, экрана нет. Кнопка «Сравнить» на карточке никуда не ведёт.
5. **Сохранить поиск с хаба.** `savedSearches` в сиде, на `SearchHubView` кнопки нет. Вкладка «Поиски» мёртвая для нового фильтра.

## Later

- SwiftUI-pro: фиксированные `font(size:)` без Dynamic Type; `PhotoPager` в том же файле, что деталь; `Binding(get:set:)` в фильтрах; иконка `plus` без видимого `Label`.
- Hallmark/slop: кнопка «Показать N» no-op; бейджи ТОП/VIN/Новый плотные (не спам, но тесно); не изобретать 01/02 и stat-row.
- Security: `Link(destination: URL(string: "tel:…")!)` упадёт на пустом телефоне; `report()` no-op; телефон в UIPasteboard без срока жизни.
- Firebase-safety: клиент пока на `seed.json` — **не** деплоить `firestore.rules`, **не** трогать `yoga_*` / `users/{uid}`. Saved search этот раунд локальный. Коллекции только `autora_*`.

## Hallmark (audit, не редизайн палитры)

Палитра [[UI-Design]] уже locked (бумага `#F4F1EA`, бронза ТОП, угольный ink). Drift: light-only theme, белый pill на фото, карточка без обрезки фото.

> [!warning] Не копировать av.by и не ставить SaaS-герой с градиентом.
