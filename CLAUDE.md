# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & run

Open `BookChecker.xcodeproj` in Xcode and Run, or from CLI:

```bash
# Build for simulator (sanity check after Swift changes)
xcodebuild -project BookChecker.xcodeproj -scheme BookChecker -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

- Bundle ID: `com.ivancabezon.BookChecker`
- Deployment target: iOS 26.5 (project setting — `IPHONEOS_DEPLOYMENT_TARGET`)
- No test target yet; no lint/format tooling configured.

The Xcode project uses `PBXFileSystemSynchronizedRootGroup` for the `BookChecker/` folder, so **adding, moving, or renaming files on disk auto-syncs into the project** — do not hand-edit `project.pbxproj` to add sources.

When SourceKit reports symbols from `Vision`, `VisionKit`, `SwiftUI`, `SwiftData`, or `UIKit` as missing while `xcodebuild` succeeds, trust the build — SourceKit in this environment runs without the iOS SDK index.

## Architecture

The app is a single-target SwiftUI iOS app, client-only (no backend), with SwiftData for persistence and a TabView root (`Scanner` + `Library`).

### Data model — CloudKit-safe persistence

`Book` (SwiftData `@Model`) is intentionally shaped to survive CloudKit's restrictions:

- Enums (`decision`, `keepReason`) are stored as `String` raw values (`decisionRaw`, `keepReasonRaw`) with **computed property accessors** exposing the typed enum. CloudKit cannot persist raw-value enums directly — every new enum field on `Book` must follow this pattern.
- Binary data (`photoData`) uses `@Attribute(.externalStorage)` so SwiftData stores it as a file reference, not inline.
- Pricing fields keep both bounds *and* a sample (`priceMin`, `priceMax`, `listingsSample`) so the UI can detect outliers, not just the cheapest listing.

CloudKit sync is **not yet wired**: `BookCheckerApp.swift` uses a local `ModelConfiguration`. There is a TODO comment that documents the exact line to switch on once the iCloud container exists in App Store Connect (`cloudKitDatabase: .private("iCloud.com.ivancabezon.BookChecker")`).

### Service layer — protocol + resolver/aggregator

Both metadata and pricing follow the same shape: a `Provider` protocol with concrete implementations, plus a coordinating actor.

- **Metadata** (`Services/Metadata/`) — `MetadataResolver` is a *fallback chain*. It iterates providers (Open Library first, Google Books second) and returns the first `BookMetadata` whose `isUsable` is true (title set AND non-empty authors). Order in the providers array defines priority.
- **Pricing** (`Services/Pricing/`) — `PricingAggregator` is a *parallel fan-out* using `withTaskGroup`. It calls every provider concurrently and returns every `PricingResult` with `listingsCount > 0`. The aggregator does not pick a winner — the caller compares results across sources.

When adding a new metadata source, plug it into the resolver chain in priority order. When adding a new pricing source, just append to the aggregator's providers — order does not matter.

### Pricing providers are scrapers

`IberlibroService` and `TodocoleccionService` are HTML scrapers (currently stubs returning `PricingResult.empty`). Real implementations parse:

- Iberlibro: `https://www.iberlibro.com/servlet/SearchResults?isbn={isbn}`
- Todocoleccion: `https://www.todocoleccion.net/buscador?bu={isbn}`

If in-app scraping becomes problematic (App Review, anti-bot), the planned fallback is to move the parsers to a Cloudflare Worker and have the provider call that — the `PricingProvider` protocol surface stays the same.

### Scanner

`ISBNScanner` is a `UIViewControllerRepresentable` wrapping `DataScannerViewController`. It must import **both** `Vision` (for symbology enums `.ean13`/`.ean8`/`.upce`) and `VisionKit`. It has a 2-second dedupe window on identical payloads and fires haptic feedback on detect.

### Scan pipeline (currently incomplete)

`ScannerView.handle(isbn:)` creates a `Book` with just the ISBN and inserts it into the context. There is a documented TODO to run `MetadataResolver` + `PricingAggregator` in the background after insert and persist the enriched data with `updatedAt = .now`. This wiring is the next major piece.

## Entitlements & permissions

- `Info.plist` declares `NSCameraUsageDescription` (required for `DataScannerViewController`).
- `BookChecker.entitlements` enables iCloud, CloudKit, and remote-notification push — these are pre-wired even though CloudKit sync is not yet active in code.
