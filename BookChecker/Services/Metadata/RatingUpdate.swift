import Foundation
import SwiftData

/// Fetches book rating from MetadataResolver providers, writes to model, saves.
/// Strategy: ISBN first, then fallback to title+author search if ISBN yields nothing.
/// No-op if neither path returns a rating.
@MainActor
func updateRating(for book: Book, using resolver: MetadataResolver, context: ModelContext) async {
    var result: BookRating?

    if let isbn = book.isbn, !isbn.isEmpty {
        result = await resolver.fetchRating(isbn: isbn)
        if result == nil {
            print("Rating: no result for ISBN \(isbn), trying title/author")
        }
    }

    if result == nil, let title = book.title, !title.isEmpty {
        result = await resolver.searchRating(title: title, author: book.authors.first)
    }

    guard let rating = result else {
        print("Rating: no result via ISBN or title/author for book \(book.title ?? book.isbn ?? "?")")
        return
    }
    print("Rating: \(rating.average) (\(rating.count ?? 0)) from \(rating.source)")
    book.rating = rating.average
    book.ratingsCount = rating.count
    book.updatedAt = .now
    try? context.save()
}
