import Foundation

struct BookDraft: Equatable {
    var isbn: String?
    var ean5: String?
    var title: String?
    var authors: [String]
    var year: Int?
    var publisher: String?
    var coverURL: URL?
    var source: String?

    init(
        isbn: String? = nil,
        ean5: String? = nil,
        title: String? = nil,
        authors: [String] = [],
        year: Int? = nil,
        publisher: String? = nil,
        coverURL: URL? = nil,
        source: String? = nil
    ) {
        self.isbn = isbn
        self.ean5 = ean5
        self.title = title
        self.authors = authors
        self.year = year
        self.publisher = publisher
        self.coverURL = coverURL
        self.source = source
    }

    static func from(metadata: BookMetadata, isbn: String?, ean5: String?) -> BookDraft {
        BookDraft(
            isbn: isbn,
            ean5: ean5,
            title: metadata.title,
            authors: metadata.authors,
            year: metadata.year,
            publisher: metadata.publisher,
            coverURL: metadata.coverURL,
            source: metadata.source
        )
    }

    func toBook() -> Book {
        Book(
            isbn: isbn,
            ean5: ean5,
            title: title,
            authors: authors,
            year: year,
            publisher: publisher,
            coverURL: coverURL
        )
    }

    var hasUsableContent: Bool {
        (title?.isEmpty == false) || (isbn?.isEmpty == false)
    }
}
