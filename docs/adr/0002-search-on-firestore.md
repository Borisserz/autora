# ADR-0002: Search on Firestore indexes, Typesense later

## Status
Accepted

## Date
2026-08-17

## Context
Фильтры объявлений многомерные. Firestore плохо комбинирует inequality. На TestFlight объявлений десятки, не 55k.

## Decision
v1: клиентская фильтрация поверх загруженного набора + составные индексы на `status+bumpedAt`. Каталог марок — бандл JSON. Typesense — когда объявлений станет много.

## Alternatives Considered

### Algolia/Typesense сразу
- Pros: полнотекст
- Cons: лишний сервис до product-market
- Rejected for v1

## Consequences
Лимит клиентской выборки. Пагинация по `bumpedAt`.
