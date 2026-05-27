import Foundation
import SwiftData

/// Fetches book rating from MetadataResolver providers, writes to model, saves.
/// No-op if ISBN missing or no provider returned a rating.
@MainActor
func updateRating(for book: Book, using resolver: MetadataResolver, context: ModelContext) async {
    guard let isbn = book.isbn, !isbn.isEmpty else { return }
    guard let rating = await resolver.fetchRating(isbn: isbn) else {
        print("Rating: no result for \(isbn)")
        return
    }
    print("Rating: \(rating.average) (\(rating.count ?? 0)) from \(rating.source) for \(isbn)")
    book.rating = rating.average
    book.ratingsCount = rating.count
    book.updatedAt = .now
    try? context.save()
}
