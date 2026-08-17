# ADR-0003: BYN primary, USD reference

## Status
Accepted

## Date
2026-08-17

## Context
av.by убрал USD по рекомендации МАРТ. Рынок считает в долларах. Нужен справочный курс, не основная цена оферты.

## Decision
Хранить `priceBYN` (целое). USD = BYN / курс НБРБ в `autora_fx/nbrb`. Тумблер в профиле. Дисклеймер «справочно».

## Alternatives Considered

### USD как основная цена
Юридический риск в РБ. Rejected.

## Consequences
Сиды и тесты используют фиксированный курс (например 2.99), продакшен — Remote Config / функция.
