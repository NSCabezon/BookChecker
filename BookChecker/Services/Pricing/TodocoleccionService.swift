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

        guard let html = await PricingScrapingHelpers.fetchHTML(url: url, session: session) else {
            return .empty
        }

        // HTML pattern: "11,41 €" — regex captures numeric, allowing nbsp/regular space.
        let prices = PricingScrapingHelpers.extractPrices(
            html: html,
            regexPattern: #"(\d+[.,]\d{2})\s*€"#
        )
        return PricingScrapingHelpers.makeResult(prices: prices, source: name)
    }
}
