import Foundation

enum ScannerState: Equatable {
    case ready
    case lookingUp(isbn: String, ean5: String?)
    case previewing(BookDraft)
    case editing(BookDraft)
    case notFound(isbn: String, ean5: String?)
    case awaitingOCR(pendingISBN: String?, pendingEAN5: String?, title: String?, authors: [String])
    case searchingByText(pendingISBN: String?, pendingEAN5: String?, title: String, authors: [String])
    case deciding(Book)
    case lookupFailed(isbn: String, ean5: String?, message: String)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var isBusy: Bool {
        switch self {
        case .lookingUp, .searchingByText: return true
        default: return false
        }
    }
}

extension ScannerState {
    static func == (lhs: ScannerState, rhs: ScannerState) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready): return true
        case let (.lookingUp(a, b), .lookingUp(c, d)): return a == c && b == d
        case let (.previewing(a), .previewing(b)): return a == b
        case let (.editing(a), .editing(b)): return a == b
        case let (.notFound(a, b), .notFound(c, d)): return a == c && b == d
        case let (.awaitingOCR(a, b, c, d), .awaitingOCR(e, f, g, h)):
            return a == e && b == f && c == g && d == h
        case let (.searchingByText(a, b, c, d), .searchingByText(e, f, g, h)):
            return a == e && b == f && c == g && d == h
        case let (.deciding(a), .deciding(b)): return a.id == b.id
        case let (.lookupFailed(a, b, c), .lookupFailed(d, e, f)):
            return a == d && b == e && c == f
        default: return false
        }
    }
}
