import Foundation
import os

enum PricingScrapingHelpers {
    static let logger = Logger(subsystem: "com.ivancabezon.BookChecker", category: "pricing")

    /// Mobile Safari UA — sites tend to serve simpler HTML to iPhone agents and
    /// don't trip basic bot filters that block generic `URLSession` UAs.
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    /// Spanish-style decimal: replaces `,` with `.` and drops thousands separators if any.
    static func parseDecimalES(_ raw: String) -> Decimal? {
        let normalized = raw.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    /// Extracts all matches of a regex with one capture group, parses each via `parseDecimalES`.
    static func extractPrices(html: String, regexPattern: String) -> [Decimal] {
        guard let regex = try? NSRegularExpression(
            pattern: regexPattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        return matches.compactMap { match -> Decimal? in
            guard match.numberOfRanges > 1,
                  let captureRange = Range(match.range(at: 1), in: html) else { return nil }
            return parseDecimalES(String(html[captureRange]))
        }
    }

    /// Builds a `PricingResult` from a list of raw prices.
    /// Filters [1, 500] EUR to drop shipping micro-amounts and outliers,
    /// sorts ascending, caps sample to 10.
    static func makeResult(prices: [Decimal], source: String) -> PricingResult {
        let one = Decimal(1)
        let cap = Decimal(500)
        let filtered = prices.filter { $0 >= one && $0 <= cap }.sorted(by: <)
        guard !filtered.isEmpty else { return .empty }
        return PricingResult(
            priceMin: filtered.first,
            priceMax: filtered.last,
            listingsSample: Array(filtered.prefix(10)),
            listingsCount: filtered.count,
            source: source,
            checkedAt: .now
        )
    }

    /// Performs a GET and returns `(body, statusCode)`. Body is nil on transport error or non-2xx.
    /// Status is nil only if the request never reached the server.
    static func fetchHTML(url: URL, session: URLSession) async -> (body: String?, status: Int?) {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("es-ES,es;q=0.9", forHTTPHeaderField: "Accept-Language")
        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode
            guard let status, (200..<300).contains(status) else {
                return (nil, status)
            }
            let body = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
            return (body, status)
        } catch {
            logger.error("HTTP error for \(url.absoluteString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return (nil, nil)
        }
    }

    /// Logs a health warning when a 200 response yields zero prices — likely sign of a layout change.
    static func logHealth(source: String, isbn: String, status: Int?, rawCount: Int, kept: Int) {
        if status == 200, rawCount == 0 {
            logger.warning("\(source, privacy: .public): HTTP 200 but 0 prices parsed for ISBN \(isbn, privacy: .public) — possible layout change")
        } else if status == 200, kept == 0, rawCount > 0 {
            logger.notice("\(source, privacy: .public): all \(rawCount) prices dropped by [1,500] filter for ISBN \(isbn, privacy: .public)")
        } else if let status, !(200..<300).contains(status) {
            logger.notice("\(source, privacy: .public): HTTP \(status) for ISBN \(isbn, privacy: .public)")
        }
    }
}
