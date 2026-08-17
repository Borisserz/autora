---
title: Full Audit
tags: [audit, testflight, ux, architecture]
date: 2026-08-17
---

# Full-Audit

/* Hallmark · pre-emit critique: P4 H5 E4 S5 R4 V4 · genre: editorial catalog · stamp: Catalogue */

Снимок **после v1-дыр** 2026-08-17 ~21:42. Не av.by. Не деплой Firebase.

**Инвентарь:** Swift в `Autora/`, 40 лотов, `catalog.json`, XCUITest 5 путей. Firebase SDK **нет**. Тесты: **76 unit + 5 UI, TEST SUCCEEDED** (iPhone 17).

`Review-Personas.md` и `Review-Critics.md` **устарели**. Не править их вместо кода.

---

## Вердикт

Покупательский и продавецский контуры на сиде **готовы к внутреннему TestFlight**.

Критерии `docs/intent/autora-v1.md`: поиск ✓ · карточка ✓ · чат/звонок ✓ · подача 2–3 мин ✓ · лот живёт после рестарта ✓.

---

## Закрыто в этом проходе

1. **Мастер «Назад»** — шаг 0 закрывает шит.
2. **Мои объявления** — тап в карточку, статус, «Вернуть», `setListingStatus` в `AppModel`.
3. **Гость + «+»** — демо-вход и сразу мастер.
4. **Удаление сохранённого поиска** — свайп; сид-поиски не возвращаются после рестарта.
5. **Своё объявление** — «Это ваше объявление», без «Позвонить».
6. **Фильтры** — «Показать N».
7. **Статы продавца** — избранное / просмотр / звонок пишут счётчики.
8. **Чат → лот** — заголовок объявления открывает карточку через deep link.
9. **Сравнение** — «Очистить».
10. **Поиск** — запрос ищет по городу и описанию.
11. **Профиль** — имя/телефон копируются на свои лоты.

---

## P0 / P1 ранее

`retryLoad` / persist / unread / wizard gates / catalog.json / рынок year±2 / nested buttons / табы SF 26pt.

---

## Архитектура / запуск

**Дыры (после Console, не этот спринт):**

1. Нет `FirestoreRepository`. Живые лоты не приедут с plist, пока нет клиента.
2. Chat rules **не деплоить** без merge на демо-чатах.
3. `autoraOnListingWrite` / notify — пустые. Ок для фазы 2.
4. Нет Privacy Policy URL — для внешнего TF + Sign in with Apple.

---

## Не делать

1. Не парсить av.by, не `#0084E6`, не «Прочее».
2. Не VIN-отчёт, не грузовики, не Algolia, не paywall на телефон.
3. Не `firebase deploy` без имён функций.
4. Не удалять Auth UID сестёр.

---

## Связанные

[[UI-Design]] [[Architecture]] [[TestFlight]] [[Firebase-Safety]] [[Avby-Flows]]
`docs/intent/autora-v1.md` · `design.md` · ADR 0001–0004
