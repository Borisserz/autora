---
title: Catalogue polish + XCUITest
date: 2026-08-17
---

# Spec — Autora Catalogue polish + UI tests

/* Hallmark · pre-emit critique: P4 H5 E4 S5 R5 V4 · genre: editorial · stamp: Catalogue */

## Goal

Внутренний TestFlight: Catalogue остаётся limestone/ink. Пять покупательских/продавецских путей прогоняются XCUITest на сиде. Визуал не крутим на новый бренд.

## Out of scope

Firebase plist, настоящий Auth, Firestore, деплой, VIN, av.by-синий, крем, фиолетовый.

## Visual / UX (внутри `design.md`)

1. Таб-иконки: один знак, большие поля, `template` + ink. TabSearch без часов, TabFavorites — сердце (та же метафора, что на карточке).
2. Мастер: `ProgressView` шага, «Готово» на клавиатуре, hit 44pt у «Далее».
3. Identifiers `autora.*` на поиск, фильтры, карточку, избранное, сравнить, Написать, мастер, чат.
4. Dynamic Type: заголовки карточек `fixedSize(horizontal: false, vertical: true)` уже есть; кнопки иконок 44pt.

## UI-testing harness

Launch argument `-ui-testing`:

- `UserDefaults(suiteName: "autora.ui-tests")`, домен чистится при старте
- В мастере кнопки «Тестовое фото» и «Тестовый черновик» (только этот режим)

## XCUITest — 5 путей

1. Хаб показывает объявления (`lst-000` или текст марки)
2. Тап карточки → деталь с ценой и «Написать»
3. Избранное с карточки → таб Избранное содержит лот
4. Подача: Войти → Новое → тестовое фото + черновик → Далее ×5 → Опубликовать → лот в «Объявления»
5. Написать без входа → алерт → Войти → Написать → поле «Сообщение»

## Success

`xcodebuild test` iPhone 17: unit + UI, зелёный. Не коммитить, пока не попросили.
