# BookChecker — Roadmap

Living doc. Priority order is opinionated, not contractual. Status as of 2026-05-27.

Legend: ✅ done · 🟡 in progress · 🔵 next up · ⚪ later · 💭 idea

---

## Done

- ✅ SwiftData model + CloudKit private DB wiring (`iCloud.com.ivancabezon.BookChecker`).
- ✅ Metadata fallback chain (Open Library → optional Google Books).
- ✅ Rating fetch (ISBN → work key → ratings.json), title/author fallback.
- ✅ Pricing scrapers (Iberlibro + Todocoleccion) with [1, 500] EUR filter.
- ✅ Aggregator parallel fan-out + `combinedPricing`.
- ✅ End-to-end scan flow: barcode → metadata → preview → confirm → decide.
- ✅ OCR mode for ISBN-less books + post-NotFound cover-OCR fallback.
- ✅ EAN-5 add-on capture (right-adjacent 5-digit text).
- ✅ Manual ISBN entry, manual pricing sheet, manual user rating sheet.
- ✅ Library list with decision filter, swipe-to-delete with confirmation.
- ✅ Book detail with inline ISBN re-scan + refresh rating/pricing.

---

## Priority 1 — Robustness of existing flows

### Scraper hardening ✅
- ✅ Class-scoped regex: Iberlibro now requires `class="…item-price…"` (excludes `item-shipping…` and the misc `EUR X,YY` strings on the page). Todocoleccion requires `class="…card-price…"`.
- ✅ Per-source XCTest suite with 4 real HTML fixtures + hand-crafted edge fragments in `BookCheckerTests/`.
- ✅ `Logger` (subsystem `com.ivancabezon.BookChecker`, category `pricing`) replaces raw `print` inside helpers; `logHealth` warns on `HTTP 200 + 0 prices` (layout-change signal) and on `200 + all dropped by filter`.
- ⚪ Did **not** adopt SwiftSoup / swift-html-to-markdown — class-anchored regex was enough; revisit if the markup grows nested. Surface stays compatible.
- **Plan B if Apple/anti-bot pushes back**: move scraping to a Cloudflare Worker. Keep `PricingProvider` protocol surface stable; the worker just becomes the URL behind `URLSession`.

### Background enrichment reliability 🔵
`ScannerView.confirm` fires fire-and-forget `Task {}` chains. If the book is deleted before tasks complete, writes may hit a freed model.

- Guard each task with `book.modelContext != nil` before mutating.
- Consider a `BookEnrichmentService` actor that holds a queue + cancellation by `book.id` (deletion cancels in-flight work).
- Surface "enriching…" indicator in `LibraryView` row while a task is in flight.

### Network error UX ⚪
Today, failures fall through silently to `notFound` / `print` logs.

- Distinguish offline vs not-found vs provider-down.
- `LookupFailedCard` shows for provider exceptions; add reachability check.
- Add retry-with-backoff inside providers (1 retry @ 500ms).

---

## Priority 2 — User-requested features

### Swipe-gesture decision overlay 🔵
From pending memory: replace decision buttons with swipes on `DecisionOverlay`.
- ↑ keep
- ↓ donate
- ← / → sell
- Double-tap pending

Keep the buttons as fallback (a11y + discoverability).

### Photo capture for ISBN-less books ⚪
Field exists (`Book.photoData`). Wire up:
- Camera picker in `BookDetailView` ("Add photo" button).
- Compress on capture (HEIC, max 1024px long edge) — CloudKit row size limits.
- Display thumbnail in `BookRow` when present (replaces title/author block? or beside?).
- Consider switching to `CKAsset` once photos are commonly used (current inline storage is fine for occasional use).

### Cover image rendering ⚪
`Book.coverURL` is populated but never shown.
- `AsyncImage` in row + detail.
- Cache to disk via `URLCache` (no extra dep).
- Fallback art when nil.

---

## Priority 3 — Library polish

### Search 🔵
No search currently. With CloudKit sync, libraries can grow large.
- Search by title, author, ISBN, notes.
- `searchable` modifier on `LibraryView` with `Predicate<Book>`.

### Sort options ⚪
Only `updatedAt desc`. Add:
- Title A→Z
- Author A→Z
- Price (min, desc)
- Rating (desc)
- Date added

### Group/section views ⚪
- By decision (collapsible sections).
- By author.
- By year/decade.

### Stats screen 💭
Tab 3: "Stats" — count by decision, total estimated value (sum of `priceMin`), avg rating, books-per-month chart.

---

## Priority 4 — Data + sync

### Export / import 🔵
- Export library to CSV / JSON via `ShareLink`.
- Import from CSV (Goodreads export format would be a strong w).

### Conflict handling for CloudKit ⚪
SwiftData+CloudKit handles basic merges, but:
- Manual edits during sync can produce surprising results.
- Add `mergeStrategy` consideration once multi-device usage is real.

### Schema versioning ⚪
First migration will be needed when a new required field arrives. Use SwiftData's `SchemaMigrationPlan`.

### CloudKit production deploy 🔵
Schema currently in development env. Before TestFlight:
- Deploy schema to production in CloudKit Console.
- Flip `aps-environment` to `production`.

---

## Priority 5 — New providers / data sources

### More metadata sources ⚪
- ISBNdb (paid API, very thorough).
- Casa del Libro / FNAC scraping (Spanish-market relevance).
- WorldCat (broad library coverage).

### More pricing sources ⚪
- Wallapop (used market, very Spanish, but app-only API).
- Amazon Marketplace (anti-bot heavy; via Worker).
- AbeBooks (parent of Iberlibro — may yield duplicate data).
- Local bookshop chains (Casa del Libro used section).

### Rating sources ⚪
- Goodreads (no public API anymore; would need scraping or third-party mirror).
- Amazon star rating (anti-bot; via Worker).

---

## Priority 6 — Architecture / DX

### Tests 🟡
- ✅ `BookCheckerTests/Pricing/` — scraper fixtures (`Resources/{Iberlibro,Todocoleccion}/*.html`) + parsing assertions + helper unit tests. **Requires test target setup in Xcode** (see PR description for scraper-hardening).
- ⚪ `BookCheckerTests/Metadata/` — JSON fixtures from Open Library / Google Books.
- ⚪ `BookCheckerTests/BookDraft` — `from(metadata:)` → `toBook()` round-trip.

### Logging ⚪
`print` everywhere. Switch to `Logger` with subsystems:
- `com.ivancabezon.BookChecker.scanner`
- `com.ivancabezon.BookChecker.metadata`
- `com.ivancabezon.BookChecker.pricing`

### Localization 💭
UI strings are hardcoded Spanish. Move to `Localizable.xcstrings` and add EN.

### Settings screen 💭
- Toggle Google Books on/off (currently env-var only).
- Toggle per-pricing-provider.
- Currency display preference (EUR is hardcoded).
- Reset CloudKit zone (dev convenience).

### Widget / Shortcut 💭
- Widget: "Last decision" / "X books pending".
- App Intent: "Lookup ISBN" via Shortcuts/Siri.

---

## Tracking

When something moves from 🔵 → 🟡 → ✅:
1. Update the bullet here.
2. Update `memory/project_bookchecker_pending.md` (priorities only).
3. If the architectural shape changes, update `CLAUDE.md` (not this file).

Items marked 💭 are speculative — promote to ⚪ when there's a real reason to build them.
