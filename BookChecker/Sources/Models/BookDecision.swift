import Foundation

enum BookDecision: String, Codable, CaseIterable, Identifiable {
    case pending
    case keep
    case sell
    case donate

    var id: String { rawValue }
}
