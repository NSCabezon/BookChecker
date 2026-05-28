import Foundation
import XCTest

enum FixtureLoader {
    /// Loads an HTML fixture from the test bundle, decoding UTF-8 first and falling back to
    /// ISO Latin-1 — mirrors the production decoder in `PricingScrapingHelpers.fetchHTML`.
    static func html(_ path: String, file: StaticString = #file, line: UInt = #line) throws -> String {
        let bundle = Bundle(for: FixtureBundleAnchor.self)
        guard let url = bundle.url(forResource: path, withExtension: nil) else {
            XCTFail("Missing fixture: \(path)", file: file, line: line)
            throw FixtureError.notFound(path)
        }
        let data = try Data(contentsOf: url)
        if let s = String(data: data, encoding: .utf8) { return s }
        if let s = String(data: data, encoding: .isoLatin1) { return s }
        throw FixtureError.undecodable(path)
    }
}

private final class FixtureBundleAnchor {}

enum FixtureError: Error {
    case notFound(String)
    case undecodable(String)
}
