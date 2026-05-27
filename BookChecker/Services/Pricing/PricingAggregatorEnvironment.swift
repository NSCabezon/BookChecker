import SwiftUI

private struct PricingAggregatorKey: EnvironmentKey {
    static let defaultValue: PricingAggregator = .makeDefault()
}

extension EnvironmentValues {
    var pricingAggregator: PricingAggregator {
        get { self[PricingAggregatorKey.self] }
        set { self[PricingAggregatorKey.self] = newValue }
    }
}

extension PricingAggregator {
    static func makeDefault() -> PricingAggregator {
        PricingAggregator(providers: [IberlibroService(), TodocoleccionService()])
    }
}
