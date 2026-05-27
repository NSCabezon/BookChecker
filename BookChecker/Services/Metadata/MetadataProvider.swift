import Foundation

struct BookMetadata: Sendable, Equatable {
    var title: String?
    var authors: [String]
    var publisher: String?
    var year: Int?
    var coverURL: URL?
    var source: String

    var isUsable: Bool {
        title != nil && !authors.isEmpty
    }
}

protocol MetadataProvider: Sendable {
    var name: String { get }
    func fetchMetadata(isbn: String) async -> BookMetadata?
    func searchMetadata(title: String, author: String?) async -> BookMetadata?
}

extension MetadataProvider {
    func searchMetadata(title: String, author: String?) async -> BookMetadata? { nil }
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
}
