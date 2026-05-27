import Foundation

struct OpenLibraryService: MetadataProvider {
    let name = "Open Library"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchMetadata(isbn: String) async -> BookMetadata? {
        var components = URLComponents(string: "https://openlibrary.org/api/books")!
        components.queryItems = [
            URLQueryItem(name: "bibkeys", value: "ISBN:\(isbn)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "jscmd", value: "data"),
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("BookChecker/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            return decode(data: data, isbn: isbn)
        } catch {
            return nil
        }
    }

    private func decode(data: Data, isbn: String) -> BookMetadata? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entry = json["ISBN:\(isbn)"] as? [String: Any] else {
            return nil
        }

        let title = entry["title"] as? String
        let authors = (entry["authors"] as? [[String: Any]] ?? [])
            .compactMap { $0["name"] as? String }
        let publisher = (entry["publishers"] as? [[String: Any]])?
            .first?["name"] as? String
        let year = (entry["publish_date"] as? String).flatMap(extractYear)
        let coverDict = entry["cover"] as? [String: String]
        let coverURL = (coverDict?["large"] ?? coverDict?["medium"] ?? coverDict?["small"])
            .flatMap(URL.init(string:))

        return BookMetadata(
            title: title,
            authors: authors,
            publisher: publisher,
            year: year,
            coverURL: coverURL,
            source: name
        )
    }

    private func extractYear(_ raw: String) -> Int? {
        if let match = raw.range(of: "\\b(19|20)\\d{2}\\b", options: .regularExpression) {
            return Int(raw[match])
        }
        return nil
    }
}
