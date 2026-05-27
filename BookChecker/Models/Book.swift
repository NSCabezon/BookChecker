import Foundation
import SwiftData

@Model
final class Book {
    // CloudKit requirements: no `.unique` constraints, no `.externalStorage`,
    // all non-optional properties must have a default value at declaration.
    var id: UUID = UUID()
    var isbn: String?
    var ean5: String?
    var title: String?
    var authors: [String] = []
    var year: Int?
    var publisher: String?
    var coverURL: URL?

    var decisionRaw: String = BookDecision.pending.rawValue
    var keepReasonRaw: String?
    var notes: String?

    var priceMin: Decimal?
    var priceMax: Decimal?
    var listingsSample: [Decimal] = []
    var listingsCount: Int?
    var priceCheckedAt: Date?

    var rating: Double?
    var ratingsCount: Int?
    var userRating: Double?

    var photoData: Data?

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        isbn: String? = nil,
        ean5: String? = nil,
        title: String? = nil,
        authors: [String] = [],
        year: Int? = nil,
        publisher: String? = nil,
        coverURL: URL? = nil,
        decision: BookDecision = .pending,
        keepReason: KeepReason? = nil,
        notes: String? = nil,
        priceMin: Decimal? = nil,
        priceMax: Decimal? = nil,
        listingsSample: [Decimal] = [],
        listingsCount: Int? = nil,
        priceCheckedAt: Date? = nil,
        rating: Double? = nil,
        ratingsCount: Int? = nil,
        userRating: Double? = nil,
        photoData: Data? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.isbn = isbn
        self.ean5 = ean5
        self.title = title
        self.authors = authors
        self.year = year
        self.publisher = publisher
        self.coverURL = coverURL
        self.decisionRaw = decision.rawValue
        self.keepReasonRaw = keepReason?.rawValue
        self.notes = notes
        self.priceMin = priceMin
        self.priceMax = priceMax
        self.listingsSample = listingsSample
        self.listingsCount = listingsCount
        self.priceCheckedAt = priceCheckedAt
        self.rating = rating
        self.ratingsCount = ratingsCount
        self.userRating = userRating
        self.photoData = photoData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var decision: BookDecision {
        get { BookDecision(rawValue: decisionRaw) ?? .pending }
        set { decisionRaw = newValue.rawValue }
    }

    var keepReason: KeepReason? {
        get { keepReasonRaw.flatMap(KeepReason.init(rawValue:)) }
        set { keepReasonRaw = newValue?.rawValue }
    }
}
