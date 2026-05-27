import Foundation

enum KeepReason: String, Codable, CaseIterable, Identifiable {
    case sentimental
    case personalInterest
    case preISBN
    case other

    var id: String { rawValue }
}
