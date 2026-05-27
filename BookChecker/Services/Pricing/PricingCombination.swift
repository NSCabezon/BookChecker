import Foundation
import SwiftData

/// Combines N `PricingResult` into a single aggregate (min of mins, max of maxes,
/// sample concat capped at 20, summed count). Returns nil if all results are empty.
func combinedPricing(_ results: [PricingResult]) -> PricingResult? {
    let nonEmpty = results.filter { $0.listingsCount > 0 }
    guard !nonEmpty.isEmpty else { return nil }

    let mins = nonEmpty.compactMap(\.priceMin)
    let maxes = nonEmpty.compactMap(\.priceMax)
    let mergedSample = Array(nonEmpty.flatMap(\.listingsSample).prefix(20))
    let totalCount = nonEmpty.map(\.listingsCount).reduce(0, +)
    let sources = nonEmpty.map(\.source).joined(separator: ", ")

    return PricingResult(
        priceMin: mins.min(),
        priceMax: maxes.max(),
        listingsSample: mergedSample,
        listingsCount: totalCount,
        source: sources,
        checkedAt: .now
    )
}

/// Fetches pricing for the book's ISBN, writes back to the SwiftData model, saves.
/// No-op if the book has no ISBN or all providers return empty.
@MainActor
func updatePricing(for book: Book, using aggregator: PricingAggregator, context: ModelContext) async {
    guard let isbn = book.isbn, !isbn.isEmpty else { return }
    let results = await aggregator.fetchAll(isbn: isbn)
    guard let combined = combinedPricing(results) else {
        print("Pricing: no results for \(isbn)")
        return
    }
    print("Pricing: combined \(combined.listingsCount) listings from \(combined.source) for \(isbn)")
    book.priceMin = combined.priceMin
    book.priceMax = combined.priceMax
    book.listingsSample = combined.listingsSample
    book.listingsCount = combined.listingsCount
    book.priceCheckedAt = .now
    book.updatedAt = .now
    try? context.save()
}
