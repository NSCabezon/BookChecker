import Foundation

struct PricingResult: Sendable {
    var priceMin: Decimal?
    var priceMax: Decimal?
    var listingsSample: [Decimal]
    var listingsCount: Int
    var source: String
    var checkedAt: Date

    static let empty = PricingResult(
        priceMin: nil,
        priceMax: nil,
        listingsSample: [],
        listingsCount: 0,
        source: "",
        checkedAt: .now
    )
}

protocol PricingProvider: Sendable {
    var name: String { get }
    func fetchPricing(isbn: String) async -> PricingResult
}

actor PricingAggregator {
    private let providers: [any PricingProvider]

    init(providers: [any PricingProvider]) {
        self.providers = providers
    }

    func fetchAll(isbn: String) async -> [PricingResult] {
        await withTaskGroup(of: PricingResult.self) { group in
            for provider in providers {
                group.addTask { await provider.fetchPricing(isbn: isbn) }
            }
            var results: [PricingResult] = []
            for await result in group where result.listingsCount > 0 {
                results.append(result)
            }
            return results
        }
    }
}
