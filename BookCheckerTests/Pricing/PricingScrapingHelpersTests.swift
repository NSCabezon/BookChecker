import XCTest
@testable import BookChecker

final class PricingScrapingHelpersTests: XCTestCase {

    func test_parseDecimalES_basic() {
        XCTAssertEqual(PricingScrapingHelpers.parseDecimalES("10,44"), Decimal(string: "10.44"))
        XCTAssertEqual(PricingScrapingHelpers.parseDecimalES("0,99"), Decimal(string: "0.99"))
    }

    func test_parseDecimalES_thousandsSeparator() {
        XCTAssertEqual(PricingScrapingHelpers.parseDecimalES("1.234,56"), Decimal(string: "1234.56"))
    }

    func test_parseDecimalES_garbage_returnsNil() {
        XCTAssertNil(PricingScrapingHelpers.parseDecimalES("abc"))
    }

    func test_makeResult_filtersBelowOneEUR() {
        let prices = [Decimal(string: "0.99")!, Decimal(string: "5.00")!, Decimal(string: "10.00")!]
        let result = PricingScrapingHelpers.makeResult(prices: prices, source: "test")

        XCTAssertEqual(result.listingsCount, 2)
        XCTAssertEqual(result.priceMin, Decimal(string: "5.00"))
        XCTAssertEqual(result.priceMax, Decimal(string: "10.00"))
    }

    func test_makeResult_filtersAbove500EUR() {
        let prices = [Decimal(string: "10.00")!, Decimal(string: "20.00")!, Decimal(string: "9999.00")!]
        let result = PricingScrapingHelpers.makeResult(prices: prices, source: "test")

        XCTAssertEqual(result.listingsCount, 2)
        XCTAssertEqual(result.priceMax, Decimal(string: "20.00"))
    }

    func test_makeResult_capsSampleAtTen() {
        let prices = (1...20).map { Decimal($0) }
        let result = PricingScrapingHelpers.makeResult(prices: prices, source: "test")

        XCTAssertEqual(result.listingsCount, 20)
        XCTAssertEqual(result.listingsSample.count, 10)
        XCTAssertEqual(result.listingsSample.first, Decimal(1))
        XCTAssertEqual(result.listingsSample.last, Decimal(10))
    }

    func test_makeResult_sortsAscending() {
        let prices = [Decimal(50), Decimal(10), Decimal(30)]
        let result = PricingScrapingHelpers.makeResult(prices: prices, source: "test")

        XCTAssertEqual(result.listingsSample, [Decimal(10), Decimal(30), Decimal(50)])
    }

    func test_makeResult_allFiltered_returnsEmpty() {
        let prices = [Decimal(string: "0.50")!, Decimal(string: "0.99")!]
        let result = PricingScrapingHelpers.makeResult(prices: prices, source: "test")

        XCTAssertEqual(result.listingsCount, 0)
        XCTAssertNil(result.priceMin)
    }

    func test_extractPrices_singleCaptureGroup() {
        let html = "<p>EUR 5,99</p><p>EUR 12,34</p>"
        let prices = PricingScrapingHelpers.extractPrices(
            html: html,
            regexPattern: #"EUR\s+(\d+[.,]\d{2})"#
        )
        XCTAssertEqual(prices, [Decimal(string: "5.99")!, Decimal(string: "12.34")!])
    }
}
