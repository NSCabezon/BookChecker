import Foundation
import SwiftUI

enum KeepReason: String, Codable, CaseIterable, Identifiable {
    case sentimental
    case personalInterest
    case preISBN
    case other

    var id: String { rawValue }

    var displayKey: LocalizedStringKey {
        switch self {
        case .sentimental: return "keep_reason_sentimental"
        case .personalInterest: return "keep_reason_personal_interest"
        case .preISBN: return "keep_reason_pre_isbn"
        case .other: return "keep_reason_other"
        }
    }
}
