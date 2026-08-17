---
title: Architecture
tags: [architecture, ios, firebase]
date: 2026-08-17
---

# Architecture

Autora — SwiftUI-клиент + Firebase ecosystem.

```
AutoraApp
  AppModel (listings, favorites, chats, session, fx)
    SeedLoader ← Autora/Resources/seed.json (сейчас единственный источник)
    FirestoreRepository  ← не реализован, ждать GoogleService-Info.plist
Domain: ListingFilter, PriceConverter, BumpPolicy, ListingSort, ListingDraft
```

Живые `autora_*` коллекции не читаются клиентом. Сид + UserDefaults (избранное, поиски, блок, жалобы).

Табы: Поиск, Избранное, Объявления, Сообщения, Профиль.

Связанные: [[Firebase-Safety]] [[UI-Design]] [[Avby-Flows]]
