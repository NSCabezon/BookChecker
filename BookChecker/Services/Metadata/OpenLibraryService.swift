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
            averageRating: nil,
            ratingsCount: nil,
            source: name
        )
    }

    private func extractYear(_ raw: String) -> Int? {
        if let match = raw.range(of: "\\b(19|20)\\d{2}\\b", options: .regularExpression) {
            return Int(raw[match])
        }
        return nil
    }

    // MARK: - Rating (2-step: ISBN → work key → ratings.json)

    func fetchRating(isbn: String) async -> BookRating? {
        guard let workKey = await fetchWorkKey(isbn: isbn) else { return nil }
        return await fetchRatingForWork(workKey: workKey)
    }

    private func fetchWorkKey(isbn: String) async -> String? {
        guard let url = URL(string: "https://openlibrary.org/isbn/\(isbn).json") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("BookChecker/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let works = json["works"] as? [[String: Any]],
                  let key = works.first?["key"] as? String else { return nil }
            // key like "/works/OL36287W" — strip leading slash for use in next URL.
            return key.hasPrefix("/") ? String(key.dropFirst()) : key
        } catch {
            return nil
        }
    }

    func searchRating(title: String, author: String?) async -> BookRating? {
        guard let workKey = await searchWorkKey(title: title, author: author) else { return nil }
        return await fetchRatingForWork(workKey: workKey)
    }

    private func searchWorkKey(title: String, author: String?) async -> String? {
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        var items = [URLQueryItem(name: "title", value: title), URLQueryItem(name: "limit", value: "1")]
        if let author { items.append(URLQueryItem(name: "author", value: author)) }
        components.queryItems = items
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("BookChecker/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let docs = json["docs"] as? [[String: Any]],
                  let key = docs.first?["key"] as? String else { return nil }
            return key.hasPrefix("/") ? String(key.dropFirst()) : key
        } catch {
            return nil
        }
    }

    private func fetchRatingForWork(workKey: String) async -> BookRating? {
        guard let url = URL(string: "https://openlibrary.org/\(workKey)/ratings.json") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("BookChecker/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let summary = json["summary"] as? [String: Any],
                  let average = summary["average"] as? Double else { return nil }
            let count = summary["count"] as? Int
            // Drop ratings with zero votes — Open Library returns 0/0 for unrated works.
            guard average > 0 else { return nil }
            return BookRating(average: average, count: count, source: name)
        } catch {
            return nil
        }
    }
}
