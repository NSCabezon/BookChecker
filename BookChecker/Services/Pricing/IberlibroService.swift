import Foundation

struct IberlibroService: PricingProvider {
    let name = "Iberlibro"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPricing(isbn: String) async -> PricingResult {
        var components = URLComponents(string: "https://www.iberlibro.com/servlet/SearchResults")!
        components.queryItems = [URLQueryItem(name: "isbn", value: isbn)]
        guard let url = components.url else { return .empty }

        let (html, status) = await PricingScrapingHelpers.fetchHTML(url: url, session: session)
        guard let html else {
            PricingScrapingHelpers.logHealth(source: name, isbn: isbn, status: status, rawCount: 0, kept: 0)
            return .empty
        }
        let prices = Self.parsePrices(html: html)
        let result = PricingScrapingHelpers.makeResult(prices: prices, source: name)
        PricingScrapingHelpers.logHealth(source: name, isbn: isbn, status: status, rawCount: prices.count, kept: result.listingsCount)
        return result
    }

    /// Extracts only item-listing prices, scoped to `<p class="item-price" ...>EUR X,YY` markup.
    /// This excludes shipping costs (rendered in `item-shipping-price-group` / `free-shipping item-shipping`)
    /// and any other `EUR X,YY` occurrences (refinement filters, totals, footer).
    static func parsePrices(html: String) -> [Decimal] {
        // Anchor: a <p> (or other tag) carrying the `item-price` class, followed by `EUR 12,34`.
        // The class list can contain other tokens — match `class="...item-price..."` loosely.
        // Use word boundary so we don't accidentally match `item-price-group` or `item-price-error`.
        let pattern = #"class="[^"]*\bitem-price\b[^"]*"[^>]*>\s*EUR\s+(\d+[.,]\d{2})"#
        return PricingScrapingHelpers.extractPrices(html: html, regexPattern: pattern)
    }
}
