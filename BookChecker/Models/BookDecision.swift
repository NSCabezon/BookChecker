import Foundation
import SwiftUI

enum BookDecision: String, Codable, CaseIterable, Identifiable {
    case pending
    case keep
    case sell
    case donate

    var id: String { rawValue }

    var displayKey: LocalizedStringKey {
        switch self {
        case .pending: return "decision_pending"
        case .keep: return "decision_keep"
        case .sell: return "decision_sell"
        case .donate: return "decision_donate"
        }
    }
}
