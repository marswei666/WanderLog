# AGENTS.md — WanderLog

## What this is

iOS travel journal app ("Kiro Book") for logging visited cafés, museums, bookstores, bars, etc. Pure SwiftUI, iOS 17+.

The Xcode scheme name is **"Kiro Book"** but the Xcode project/target is **"WanderLog"**.

## Build & run

```bash
open WanderLog.xcodeproj        # then ⌘R in Xcode, scheme "Kiro Book"
```

No SPM, no CocoaPods, no external dependencies. Pure SwiftUI + system frameworks. No Makefile, no CI, no pre-commit hooks, no SwiftLint.

## Architecture

- **Entry point**: `WanderApp.swift` — injects `EntryStore` and `LanguageManager` as `@EnvironmentObject`
- **Data persistence**: JSON files in `Documents/` directory (`entries.json`, `customCategories.json`). NOT SwiftData, NOT Core Data, NOT CoreData — plain `Codable` structs written via `JSONEncoder`
- **Photo storage**: JPEG files in `Documents/photos/`, filenames are UUID strings. `PhotoRepository` handles save/load/delete; images resized to max 1200px, 85% quality
- **Models**: `Entry` (struct, `Codable`), `CustomCategory` (struct, `Codable`), `PlaceCategory` (enum), `Mood` (enum). Entry tags are `[String]`, not a separate model
- **Custom categories**: Entries reference categories by `customCategoryID: UUID?`. `EntryStore` handles migration of old entries and orphaned IDs on init
- **Localization**: 5 languages (zh-Hans, en, ja, ko, zh-Hant). All strings go through `LanguageManager` → `Strings` struct, NOT `.strings` files. `PlaceCategory` and `Mood` have `localizedName(lang:)` extensions
- **Location**: `LocationManager` is a singleton (`@MainActor`), wraps `CLLocationManager`, reverse-geocodes to city/country
- **Translation**: `TranslationService` needs a Google Translate API key; silently no-ops if empty

### Key views

`RootView` → 4 tabs: Home (calendar), Map, Collection, Profile. Center "+" button opens `AddEntryView` as sheet.

### Design system

- Colors: `wanderInk`, `wanderCream`, `wanderAccent`, `wanderMuted`, `wanderWarm`, `wanderBlush` — defined in `DesignSystem.swift`, backed by xcassets color sets
- Font: `wanderSerif()` wraps Georgia
- `cardStyle()` modifier: white bg, rounded rect 20pt, subtle shadow
- `Color(hex:)` extension exists in `EntryCard.swift`

## Gotchas

1. **sync_wanderlog.sh is stale** — it bootstraps an older SwiftData-based version of the code. The actual Swift files use `Codable` structs + JSON files, NOT `@Model` / `ModelContainer`. Do not use this script as a source of truth.

2. **Two Entry.swift versions** — the sync script contains an old `Entry.swift` with `@Model` and `Tag` as a relationship. The real `Entry.swift` is a plain `Codable` struct with `tags: [String]` and `customCategoryID: UUID?`.

3. **Color naming** — xcassets use `WanderInk` (capital W), Swift statics use `wanderInk` (lowercase). The `Color("WanderInk")` initializer resolves the asset by name string.

4. **No tests** — there are no unit tests for the app.

5. **App name confusion** — "Kiro Book" is the display/scheme name, "WanderLog" is the project/target/bundle name.

6. **Entry migration** — `EntryStore.init()` runs three migrations automatically: seeding default categories, backfilling `sourcePlaceCategory` on custom categories (by icon match), and assigning `customCategoryID` to entries that lack one. Changing category icons will break migration.

7. **Google Translate API** — `TranslationService.apiKey` is empty by default. The app works fine without it; translations just stay in the source language for custom categories.

8. **No root `.gitignore`** — there is no root-level `.gitignore`. The `WanderLog/.gitignore` is a Flutter template (copy-paste artifact), not relevant to the Swift app.
