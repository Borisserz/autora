# ADR-0004: Demo seed isDemo

## Status
Accepted

## Date
2026-08-17

## Context
TestFlight не должен быть пустым. Парсить av.by нельзя.

## Decision
- Фикстуры `firebase/seed/` и копия в `Autora/Resources/seed.json`
- Function `autoraSeedDemo` / `autoraWipeDemo` owner-only
- Все демо-документы `isDemo: true`
- Wipe удаляет только `isDemo == true` в `autora_*`

## Alternatives Considered

### Только эмулятор
Не видно на телефоне. Rejected.

## Consequences
Фото демо — Unsplash/placeholder, не скрины av.by.
