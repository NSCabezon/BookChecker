import Foundation

struct TodocoleccionService: PricingProvider {
    let name = "Todocoleccion"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPricing(isbn: String) async -> PricingResult {
        // TODO: parser HTML real. Esqueleto con fallback silencioso a empty.
        // URL típica: https://www.todocoleccion.net/buscador?bu={isbn}
        // Parsear precios visibles, devolver min/max/sample/count.
        return PricingResult.empty
    }
}
