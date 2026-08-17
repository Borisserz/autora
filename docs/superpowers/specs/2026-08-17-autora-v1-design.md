# Autora v1 design spec

Date: 2026-08-17

## Objective

TestFlight iOS app: Belarus car classifieds. Buyer search + seller post. Editorial UI. Demo data visible without scraping av.by.

## Commands

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Autora.xcodeproj -scheme Autora \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Autora.xcodeproj -scheme Autora \
  -destination 'generic/platform=iOS' build
```

## Domain

- `Listing`, `Seller`, `ChatThread`, `ChatMessage`, `SavedSearch`, `SearchCriteria`
- `PriceConverter.usd(fromBYN:rate:)`
- `BumpPolicy.canBump(lastBumped:now:)` interval 20 hours
- `ListingFilter.apply(_:to:)`
- `ListingSort`

## UI

Five tabs. Search hub cleaner than av.by. Profile not Other. Tokens in UI-Design.md.

## Data

`seed.json` in bundle. Optional Firestore `autora_*`.

## Acceptance

1. Tests for price, filter, bump, sort green
2. Simulator: listings visible, card zoom, favorites without login, post wizard, chat list from seed
3. No av.by trademarks
4. Firebase functions exist, not auto-deployed without names
