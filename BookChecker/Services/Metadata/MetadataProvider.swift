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
}
