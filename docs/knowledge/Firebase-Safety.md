---
title: Firebase Safety
tags: [firebase, safety]
date: 2026-08-17
aliases: [Firebase-Safety]
---

# Firebase Safety

Проект: `serzhanovich-ecosystem-ce700`.

> Никогда не деплой все функции. `firebase deploy --only functions` без имён снесёт Yoga/Wardrobe/Workout.

## Разрешено

```
npx -y firebase-tools@latest deploy --only functions:autoraSeedDemo,functions:autoraWipeDemo,functions:autoraOnListingWrite,functions:autoraNotifySavedSearch
```

`firebase.json` → `codebase: autora`. **Нет** ключа `firestore.rules` в деплое по умолчанию.

## Коллекции

`autora_users`, `autora_listings`, `autora_favorites`, `autora_saved_searches`, `autora_chats`, `autora_messages`, `autora_reports`, `autora_bumps`, `autora_blocks`, `autora_fx`

Storage: `autora/{uid}/listings/{id}/`, `autora/demo/`

## Не трогать

`yoga_*`, `tryon_*`, `garments`, `users/{uid}` wipe, legendary_routines, premium_recipes, stepper paths.

Сниппет правил: `firebase/firestore.autora.snippet.rules` — вклеивать в канон после аудита сестёр.
