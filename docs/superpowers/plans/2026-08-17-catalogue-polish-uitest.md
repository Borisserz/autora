# Catalogue polish + XCUITest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (user asked to implement immediately). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish Catalogue UX in-place and cover five seed use cases with XCUITest.

**Architecture:** Launch flag `-ui-testing` isolates UserDefaults and unlocks fixture buttons. Accessibility identifiers `autora.*` drive XCUITest. Visual changes stay on limestone/ink tokens.

**Tech Stack:** SwiftUI, XCUITest, iOS 18.6, iPhone 17 simulator.

## Global Constraints

- UI Russian; tests English method names
- No av.by `#0084E6`, cream `#F4F1EA`, purple
- No firebase deploy, no real Auth
- Destination: `platform=iOS Simulator,name=iPhone 17`
- DerivedData `/tmp/AutoraDerived`
- Do not commit unless asked

---

### Task 1: Harness + identifiers

**Files:**
- Create: `Autora/Design/AutoraID.swift`
- Modify: `Autora/AutoraApp.swift`
- Modify: `Autora/Services/AppModel.swift` (init already takes defaults)

**Produces:** `AutoraID` constants; `UITestLaunch.isActive`; isolated defaults.

- [ ] Add `AutoraID` and `UITestLaunch`
- [ ] Wire `AutoraApp` to wipe `autora.ui-tests` suite when `-ui-testing`

---

### Task 2: Wire identifiers + wizard UX

**Files:** SearchHubView, ListingCardView, ListingDetailView, PostWizardView, MessagesView, RootTabView, MyListingsView, FavoritesView

- [ ] Identifiers on search, filters, cards, favorite, compare, write, wizard, chat
- [ ] Wizard ProgressView + keyboard Done
- [ ] UI-testing buttons: Тестовое фото, Тестовый черновик

---

### Task 3: Tab glyphs

**Files:** `Autora/Assets.xcassets/Tab*.imageset`

- [ ] Single-sign linocut, template rendering, heart for favorites

---

### Task 4: AutoraUITests target

**Files:** `Autora.xcodeproj/project.pbxproj`, `Autora.xcscheme`, `AutoraUITests/*.swift`

- [ ] UI test target + five tests
- [ ] `xcodebuild test` iPhone 17 green
