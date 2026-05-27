import Foundation

struct GoogleBooksService: MetadataProvider {
    let name = "Google Books"

    private let session: URLSession
    private let apiKey: String?

    init(session: URLSession = .shared, apiKey: String? = nil) {
        self.session = session
        self.apiKey = apiKey
    }

    func fetchMetadata(isbn: String) async -> BookMetadata? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        var items = [URLQueryItem(name: "q", value: "isbn:\(isbn)")]
        if let apiKey {
            items.append(URLQueryItem(name: "key", value: apiKey))
        }
        components.queryItems = items
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("BookChecker/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            return try decode(data: data)
        } catch {
            return nil
        }
    }

    private func decode(data: Data) throws -> BookMetadata? {
        let payload = try JSONDecoder().decode(VolumesResponse.self, from: data)
        guard let info = payload.items?.first?.volumeInfo else { return nil }
        return BookMetadata(
            title: info.title,
            authors: info.authors ?? [],
            publisher: info.publisher,
            year: info.publishedDate.flatMap(yearFromDate),
            coverURL: info.imageLinks?.thumbnail.flatMap(URL.init(string:)),
            source: name
        )
    }

    private func yearFromDate(_ raw: String) -> Int? {
        Int(raw.prefix(4))
    }

    private struct VolumesResponse: Decodable {
        let items: [Item]?
        struct Item: Decodable { let volumeInfo: VolumeInfo }
        struct VolumeInfo: Decodable {
            let title: String?
            let authors: [String]?
            let publisher: String?
            let publishedDate: String?
            let imageLinks: ImageLinks?
        }
        struct ImageLinks: Decodable {
            let thumbnail: String?
        }
    }
}
