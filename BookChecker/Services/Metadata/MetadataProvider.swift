import Foundation

struct BookMetadata: Sendable, Equatable {
    var title: String?
    var authors: [String]
    var publisher: String?
    var year: Int?
    var coverURL: URL?
    var averageRating: Double?
    var ratingsCount: Int?
    var source: String

    var isUsable: Bool {
        title != nil && !authors.isEmpty
    }
}

struct BookRating: Sendable, Equatable {
    var average: Double
    var count: Int?
    var source: String
}

protocol MetadataProvider: Sendable {
    var name: String { get }
    func fetchMetadata(isbn: String) async -> BookMetadata?
    func searchMetadata(title: String, author: String?) async -> BookMetadata?
    func fetchRating(isbn: String) async -> BookRating?
    func searchRating(title: String, author: String?) async -> BookRating?
}

extension MetadataProvider {
    func searchMetadata(title: String, author: String?) async -> BookMetadata? { nil }
    func fetchRating(isbn: String) async -> BookRating? { nil }
    func searchRating(title: String, author: String?) async -> BookRating? { nil }
}

actor MetadataResolver {
    private let providers: [any MetadataProvider]

    init(providers: [any MetadataProvider]) {
        self.providers = providers
    }

    func fetch(isbn: String) async -> BookMetadata? {
        for provider in providers {
            if let result = await provider.fetchMetadata(isbn: isbn), result.isUsable {
                return result
            }
        }
        return nil
    }

    func search(title: String, author: String?) async -> BookMetadata? {
        for provider in providers {
            if let result = await provider.searchMetadata(title: title, author: author), result.isUsable {
                return result
            }
        }
        return nil
    }

    func fetchRating(isbn: String) async -> BookRating? {
        for provider in providers {
            if let rating = await provider.fetchRating(isbn: isbn) {
                return rating
            }
        }
        return nil
    }

    func searchRating(title: String, author: String?) async -> BookRating? {
        for provider in providers {
            if let rating = await provider.searchRating(title: title, author: author) {
                return rating
            }
        }
        return nil
    }
}
