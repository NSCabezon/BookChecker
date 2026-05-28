import Foundation

struct TodocoleccionService: PricingProvider {
    let name = "Todocoleccion"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPricing(isbn: String) async -> PricingResult {
        var components = URLComponents(string: "https://www.todocoleccion.net/buscador")!
        components.queryItems = [URLQueryItem(name: "bu", value: isbn)]
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

    /// Extracts only listing-card prices, scoped to `<span class="card-price ...">X,YY €</span>` markup.
    /// Excludes any other euro-formatted numbers on the page (filters, shipping estimates, totals).
    static func parsePrices(html: String) -> [Decimal] {
        // Anchor: tag carrying the `card-price` class, followed by `X,YY €` (with optional nbsp/space).
        let pattern = #"class="[^"]*\bcard-price\b[^"]*"[^>]*>\s*(\d+[.,]\d{2})\s*€"#
        return PricingScrapingHelpers.extractPrices(html: html, regexPattern: pattern)
    }
}
