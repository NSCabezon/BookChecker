import SwiftUI

private struct MetadataResolverKey: EnvironmentKey {
    static let defaultValue: MetadataResolver = .makeDefault()
}

extension EnvironmentValues {
    var metadataResolver: MetadataResolver {
        get { self[MetadataResolverKey.self] }
        set { self[MetadataResolverKey.self] = newValue }
    }
}

extension MetadataResolver {
    static func makeDefault() -> MetadataResolver {
        var providers: [any MetadataProvider] = [OpenLibraryService()]
        if ProcessInfo.processInfo.environment["BOOKCHECKER_ENABLE_GOOGLE_BOOKS"] != nil {
            providers.append(GoogleBooksService())
        }
        return MetadataResolver(providers: providers)
    }
}
