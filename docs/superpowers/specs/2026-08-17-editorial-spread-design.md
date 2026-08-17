---
title: Editorial catalog spread
date: 2026-08-17
---

# Spec — Autora editorial spread (A)

/* Hallmark · pre-emit critique: P5 H5 E4 S5 R5 V4 · genre: editorial · stamp: Catalogue */

## Goal

Хаб, карточка и деталь читаются как разворот каталога (Monocle / Kinfolk). Токены `design.md` не меняются. Не av.by, не крем, не стекло.

## In

1. Мастхед: serif largeTitle, дата uppercase, двойная hairline, счётчик как выпуск.
2. Карточка: фото 360, колофон (serif title, tabular цена, город, спека через `·`). «Сравнить» muted.
3. Деталь: хиро 460, цена как display, спека двумя колонками, «Похожие» как секция каталога.
4. Gutter 20. Лента spacing 36.

## Out

Чат, мастер, профиль, фильтры, Firebase, новые цвета, цена поверх фото.

## Success

XCUITest 5 путей зелёные. Идентификаторы `autora.*` без изменений.
