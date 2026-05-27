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

        guard let html = await PricingScrapingHelpers.fetchHTML(url: url, session: session) else {
            return .empty
        }

        // HTML pattern: "EUR 13,92" — regex captures the numeric part.
        // Caveat: this also picks up shipping costs alongside item prices.
        // [1, 500] EUR filter in makeResult mitigates the lowest noise.
        let prices = PricingScrapingHelpers.extractPrices(
            html: html,
            regexPattern: #"EUR\s+(\d+[.,]\d{2})"#
        )
        return PricingScrapingHelpers.makeResult(prices: prices, source: name)
    }
}
