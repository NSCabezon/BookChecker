# CLAUDE.md

Guidance for Claude Code when working in this repo.

## Build & run

Open `BookChecker.xcodeproj` in Xcode and Run, or via CLI:

```bash
# Sanity-check build after Swift changes
xcodebuild -project BookChecker.xcodeproj -scheme BookChecker -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

- Bundle ID: `com.ivancabezon.BookChecker`
- iCloud container: `iCloud.com.ivancabezon.BookChecker`
- Deployment target: iOS 26.5 (`IPHONEOS_DEPLOYMENT_TARGET`)
- No test target. No lint/format tooling.
- UI strings: Spanish. Code/identifiers: English.

Xcode project uses `PBXFileSystemSynchronizedRootGroup` for `BookChecker/` — **adding, moving, renaming files on disk auto-syncs into the project**. Never hand-edit `project.pbxproj` to add sources.

SourceKit in this env runs without iOS SDK index → reports `Vision`/`VisionKit`/`SwiftUI`/`SwiftData`/`UIKit` symbols as missing while `xcodebuild` succeeds. Trust the build.

## Architecture

Single-target SwiftUI iOS app, client-only, SwiftData + CloudKit sync, TabView root (`Scanner` + `Library`).

### Persistence — CloudKit live

`BookCheckerApp.swift` uses `ModelConfiguration(..., cloudKitDatabase: .private("iCloud.com.ivancabezon.BookChecker"))`. Entitlements + Info.plist already wired (`com.apple.developer.icloud-services` = CloudKit, `aps-environment` = development, `NSCameraUsageDescription` set).

`Book` (`Models/Book.swift`) is shaped to survive CloudKit's restrictions — every new field must follow these rules:

- **No `.unique` constraints**, no `@Attribute(.externalStorage)` — CloudKit rejects both. `photoData: Data?` stored inline (keep blobs small or move to CKAsset later).
- **All non-optional properties have a default at declaration** (`var id: UUID = UUID()`, `var authors: [String] = []`, etc.). CloudKit requires this for schema reconciliation.
- **Enums stored as `String` raw values** (`decisionRaw`, `keepReasonRaw`) with computed accessors exposing the typed enum. CloudKit cannot persist raw-value enums.

Pricing fields keep both bounds *and* a sample (`priceMin`, `priceMax`, `listingsSample`, `listingsCount`) so the UI can show range/outliers, not just the cheapest listing.

### Service layer — protocol + resolver/aggregator

Two services, same shape: `Provider` protocol + concrete implementations + coordinating actor.

- **Metadata** (`Services/Metadata/`) — `MetadataResolver` is a **fallback chain**. `fetch(isbn:)` iterates providers in order, returns first `BookMetadata` with `isUsable` true (title set AND non-empty authors). Order = priority. Default: `OpenLibraryService` only; `GoogleBooksService` appended iff env var `BOOKCHECKER_ENABLE_GOOGLE_BOOKS` is set (`MetadataResolverEnvironment.swift`).
- **Pricing** (`Services/Pricing/`) — `PricingAggregator` is a **parallel fan-out** via `withTaskGroup`. Calls every provider concurrently, returns every `PricingResult` with `listingsCount > 0`. Caller compares across sources. `PricingCombination.combinedPricing(_:)` merges N results into one (min of mins, max of maxes, sample concat capped at 20, summed count).

Resolver/aggregator exposed via `EnvironmentValues` (`\.metadataResolver`, `\.pricingAggregator`) wired in `BookCheckerApp`.

When adding:
- New metadata source → plug into resolver chain in priority order.
- New pricing source → append to aggregator; order does not matter.

### Ratings (separate flow from metadata)

`MetadataProvider` also exposes `fetchRating(isbn:)` + `searchRating(title:author:)`. `MetadataResolver` has matching methods using same fallback chain. `Services/Metadata/RatingUpdate.swift` (`updateRating(for:using:context:)`) is the SwiftData-aware writer: tries ISBN first, falls back to title+author. `Book` stores both internet rating (`rating`, `ratingsCount`) and personal rating (`userRating`).

Open Library's rating path is a 2-step API call: `ISBN → work key → /works/{key}/ratings.json`. Returns nil if `average <= 0` (OL reports 0/0 for unrated works). Title-only fallback runs when title+author yields nothing.

### Pricing providers (HTML scrapers)

`IberlibroService` + `TodocoleccionService` are working HTML scrapers. They share `PricingScrapingHelpers`:

- **User-Agent**: mobile Safari (sites serve simpler HTML to iPhone, fewer bot trips).
- **Regex single-capture-group → `parseDecimalES`** (Spanish decimals: `,` → `.`, drop thousands).
- **`makeResult`** filters `[1, 500]` EUR (drops shipping micro-amounts + outliers), sorts ascending, caps sample to 10.

Caveat: Iberlibro regex `EUR\s+(\d+[.,]\d{2})` also captures shipping; the [1, 500] filter mitigates lowest noise but max can still skew. If anti-bot blocks ever surface, planned fallback is a Cloudflare Worker exposing the same `PricingProvider` shape.

### Scanner

`Scanner/ISBNScanner.swift` — `UIViewControllerRepresentable` wrapping `DataScannerViewController`. Single controller handles **both** barcode (`.ean13/.ean8/.upce`) and text (OCR) simultaneously. Imports needed: `Vision` (symbology enums) + `VisionKit`.

Features:
- 2-second dedupe on identical `(isbn, ean5)`.
- Haptic feedback on detect (medium for barcode, light for OCR tap).
- **EAN-5 add-on detection**: scans 5-digit text bounds adjacent to the right of the EAN-13 within ~1 barcode-width, vertically aligned within barcode-height tolerance. Spanish list-price suffix.
- Torch via `AVCaptureDevice.userPreferredCamera`.

`Scanner/OCRScanner.swift` is text-only variant (currently unused — `ISBNScanner` covers both modes via `recognizedDataTypes: [.barcode(...), .text()]`).

### Scan flow (working end-to-end)

`Views/ScannerView.swift` drives a state machine (`ScannerState`):

```
ready
  ↓ barcode detected (mode = Código)
lookingUp(isbn, ean5)
  ↓ MetadataResolver.fetch
previewing(BookDraft)   →  notFound(isbn, ean5)
  ↓ confirm                 ↓ "Escanear portada"
deciding(Book)           switchToOCR + pendingISBN
  ↓ choose decision         ↓ OCR taps populate title/author
ready                    searchingByText → previewing → deciding
```

Mode toggle: segmented picker `Código` / `OCR`. Pure-OCR mode (no ISBN) lands in `previewing(draft)` with `source: "manual"`.

`confirm(_ draft:)` is the persistence point:
1. `context.insert(book)` + `context.save()`.
2. Fire `updatePricing(...)` task (background, mutates `book` on main).
3. Fire `updateRating(...)` task if no rating yet.

Both run **after** insert so user decides immediately while enrichment happens in background.

### Library + detail

`Views/LibraryView.swift` — `@Query(sort: \Book.updatedAt, order: .reverse)`, filter menu by `BookDecision`, swipe-to-delete with confirmation dialog. Row shows title, authors, decision badge, rating stars, price range.

`Views/BookDetailView.swift` — `@Bindable var book: Book`, Form sections: Metadata (with inline ISBN re-scan via `ISBNScanSheet`), Media en internet (rating + manual refresh), Mi puntuación (`ManualRatingSheet`), Decision + KeepReason picker, Pricing (refresh + `ManualPricingSheet` fallback), Notes.

### Previews

`Previews/PreviewSamples.swift` — `@MainActor` enum with `BookDraft`/`Book` fixtures and `inMemoryContainer(with:)`. Use this for any new `#Preview`. Never use the CloudKit container in previews.

## Folder layout

```
BookChecker/
├── BookCheckerApp.swift          # entry: ModelContainer (CloudKit) + RootView TabView
├── Info.plist                    # NSCameraUsageDescription, remote-notification
├── BookChecker.entitlements      # iCloud, CloudKit, aps-environment
├── Assets.xcassets/
├── Models/                       # Book, BookDecision, KeepReason, BookDraft
├── Scanner/                      # ISBNScanner, OCRScanner
├── Services/
│   ├── Metadata/                 # MetadataProvider, OpenLibrary, GoogleBooks, RatingUpdate, env
│   └── Pricing/                  # PricingProvider, Iberlibro, Todocoleccion, helpers, combination, env
├── Views/
│   ├── ScannerView.swift         # state machine + flow
│   ├── LibraryView.swift
│   ├── BookDetailView.swift
│   ├── ManualPricingSheet.swift
│   ├── ManualRatingSheet.swift
│   ├── Scanner/                  # subviews: cards, panels, overlays, sheets, state enum
│   └── Support/                  # BindingExtensions
└── Previews/                     # PreviewSamples
```

## Notes for changes

- New field on `Book` → must have default if non-optional. Enum field → store raw `String` + computed property.
- New scanner symbology → both `Vision` import + `recognizedDataTypes` array in `ISBNScanner.makeUIViewController`.
- New metadata field that should flow scan → preview → persist → add to `BookMetadata`, `BookDraft.from`, `BookDraft.toBook`, `Book`.
- Touching `ScannerView` flow → update `ScannerState` cases AND the manual `==` impl (`Book` is a class; enums with associated values need it).
- New `#Preview` → `PreviewSamples.inMemoryContainer(with:)`, never the CloudKit container.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for prioritized future improvements.
