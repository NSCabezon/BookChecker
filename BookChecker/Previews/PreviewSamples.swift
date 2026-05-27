import Foundation
import SwiftData

@MainActor
enum PreviewSamples {
    static let draftFull = BookDraft(
        isbn: "9780140449266",
        ean5: nil,
        title: "Crime and Punishment",
        authors: ["Fyodor Dostoyevsky", "David McDuff (translator)"],
        year: 2003,
        publisher: "Penguin Classics",
        coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9780140449266-L.jpg"),
        source: "OpenLibrary"
    )

    static let draftMinimal = BookDraft(
        isbn: "9788478888880",
        ean5: "00012",
        title: nil,
        authors: [],
        source: nil
    )

    static var bookSell: Book {
        Book(
            isbn: "9780140449266",
            title: "Crime and Punishment",
            authors: ["Fyodor Dostoyevsky"],
            year: 2003,
            publisher: "Penguin Classics",
            decision: .sell,
            priceMin: 8.50,
            priceMax: 22.00,
            listingsSample: [8.50, 12.00, 15.00, 22.00],
            listingsCount: 4,
            priceCheckedAt: Date(timeIntervalSince1970: 1_736_000_000)
        )
    }

    static var bookPending: Book {
        Book(
            isbn: "9788423353972",
            title: "El nombre de la rosa",
            authors: ["Umberto Eco"],
            year: 1980,
            publisher: "Lumen",
            decision: .pending
        )
    }

    static var bookKeep: Book {
        Book(
            isbn: "9788490660584",
            title: "Cien años de soledad",
            authors: ["Gabriel García Márquez"],
            year: 1967,
            publisher: "Cátedra",
            decision: .keep,
            keepReason: .sentimental
        )
    }

    static func inMemoryContainer(with books: [Book] = []) -> ModelContainer {
        let schema = Schema([Book.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        for book in books {
            container.mainContext.insert(book)
        }
        return container
    }
}
