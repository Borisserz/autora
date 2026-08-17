---
title: UI Design
tags: [design, editorial]
date: 2026-08-17
---

# UI-Design

Editorial catalog. Бренд **Autora**. Не av.by `#0084E6`, не тёплый крем `#F4F1EA`, не фиолетовый градиент.

Фото — товар. Бумага — холодный известняк. Один тёплый акцент: латунь ТОП.

## Tokens

| Token | Light | Dark |
| :--- | :--- | :--- |
| canvas | `#E6E8E5` | `#090A09` |
| surface | `#F2F3F1` | `#121412` |
| ink | `#141615` | `#E6E8E5` |
| muted | `#6C706E` | `#8A8E8C` |
| accent | `#2A2D2C` | `#C5C8C5` |
| price | ink | ink |
| badgeTop | `#9A8B5C` | `#9A8B5C` |
| danger | `#7A3D38` | `#D4A8A4` |

## Радиусы

- Фото: **24**
- Чипы / спека / поля: **4**
- Не округлять всё 16–20. Стики-бар и спека — почти плита.

## Тип

- Serif **только** wordmark «Autora» и заголовок объявления. Без курсива.
- Цена: SF tabular.
- Остальное: SF.

## Карточка

Полнокадровое фото **360**. Колофон снизу: serif title, цена tabular `.title`, город uppercase. Спека через `·`. Без белой коробки.

## Хаб

Мастхед largeTitle + дата uppercase. Двойная hairline. Gutter **20**. Лента spacing **36**. Счётчик выпуска. Поиск sticky сверху. Таббар прячется при скролле (iOS 26).

## Карточка / деталь

Цена — display (`.largeTitle` tabular). Спека двумя колонками, подписи uppercase. Хиро **460**, «3 / 12» на кадре. Потяни деталь вниз — фото тянется.

## Движение

Три примитива, не больше:

1. Zoom с карточки в деталь
2. Stagger ленты один раз (не при скролле назад)
3. Ink-press кнопок + линия под «Autora» рисуется слева

Spring на сердце снят. Reduce Motion — только opacity.

Фон: tiled `PaperGrain`. Empty states — линогравюра. Табы — один SF-знак 26pt (сердце = избранное); noisy linocut на табах убран.

Связанные: [[Review-Critics]] [[Avby-Flows]]
