# ADR-0001: Shared Firebase isolation

## Status
Accepted

## Date
2026-08-17

## Context
Autora живёт в `serzhanovich-ecosystem-ce700` рядом с Yoga, Workout, Food, Wardrobe, RPG, Stepper. Голый `firebase deploy --only functions` предлагает удалить чужие функции.

## Decision
- Firestore/Storage/Functions только с префиксом `autora`
- Functions `codebase: autora` (как Yoga: `yoga`)
- Деплой только по именам
- Rules — сниппет `firebase/firestore.autora.snippet.rules`, merge вручную, не overwrite
- Удаление аккаунта Autora не трогает Firebase Auth UID

## Alternatives Considered

### Отдельный Firebase-проект
- Pros: нулевой blast radius
- Cons: пользователь явно запретил плодить проект
- Rejected

## Consequences
Нужен owner UID в `OWNER_UIDS` для seed/wipe. Клиент работает с локальным seed.json до регистрации iOS app в Console.
