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
        await query(q: "isbn:\(isbn)")
    }

    func searchMetadata(title: String, author: String?) async -> BookMetadata? {
        let titlePart = "intitle:\(title)"
        let authorPart = author.map { "+inauthor:\($0)" } ?? ""
        return await query(q: titlePart + authorPart)
    }

    func fetchRating(isbn: String) async -> BookRating? {
        guard let metadata = await query(q: "isbn:\(isbn)"),
              let avg = metadata.averageRating else { return nil }
        return BookRating(average: avg, count: metadata.ratingsCount, source: name)
    }

    private func query(q: String) async -> BookMetadata? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        var items = [URLQueryItem(name: "q", value: q)]
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
            averageRating: info.averageRating,
            ratingsCount: info.ratingsCount,
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
            let averageRating: Double?
            let ratingsCount: Int?
        }
        struct ImageLinks: Decodable {
            let thumbnail: String?
        }
    }
}
