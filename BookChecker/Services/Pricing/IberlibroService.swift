import Foundation

struct IberlibroService: PricingProvider {
    let name = "Iberlibro"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPricing(isbn: String) async -> PricingResult {
        // TODO: parser HTML real. Esqueleto con fallback silencioso a empty.
        // URL típica: https://www.iberlibro.com/servlet/SearchResults?isbn={isbn}
        // Parsear precios visibles, devolver min/max/sample/count.
        return PricingResult.empty
    }
}
