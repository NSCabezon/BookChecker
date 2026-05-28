import XCTest
@testable import BookChecker

final class IberlibroServiceTests: XCTestCase {

    func test_parsePrices_quijote_extractsOnlyItemPrices() throws {
        let html = try FixtureLoader.html("Resources/Iberlibro/quijote.html")
        let prices = IberlibroService.parsePrices(html: html)

        // Should pull the 10 listing prices that the page renders (matches manual count).
        XCTAssertEqual(prices.count, 10)

        // All values must be inside a sane range — previously the regex picked up
        // shipping micro-amounts like EUR 0,99 / EUR 1,00.
        XCTAssertTrue(prices.allSatisfy { $0 >= Decimal(string: "1.00")! })
        XCTAssertTrue(prices.allSatisfy { $0 <= Decimal(string: "50.00")! })

        // Spot-check: the cheapest listing on this page is EUR 5,65.
        XCTAssertEqual(prices.min(), Decimal(string: "5.65"))
    }

    func test_parsePrices_sample2_extractsOnlyItemPrices() throws {
        let html = try FixtureLoader.html("Resources/Iberlibro/sample2.html")
        let prices = IberlibroService.parsePrices(html: html)

        XCTAssertEqual(prices.count, 10)
        XCTAssertTrue(prices.allSatisfy { $0 >= Decimal(string: "1.00")! })
        XCTAssertEqual(prices.min(), Decimal(string: "2.40"))
    }

    func test_parsePrices_ignoresShippingMarkup() {
        // Hand-crafted fragment: one real listing price + a shipping span with EUR 0,99.
        let html = """
        <div class="item-price-group">
          <p class="item-price" id="item-price-1">EUR 7,50</p>
        </div>
        <div class="item-shipping-price-group">
          <span class="free-shipping item-shipping">Gastos de envío gratis</span>
          <span class="item-shipping-price">EUR 0,99</span>
        </div>
        """
        let prices = IberlibroService.parsePrices(html: html)
        XCTAssertEqual(prices, [Decimal(string: "7.50")!])
    }

    func test_parsePrices_emptyHTML_returnsEmpty() {
        XCTAssertTrue(IberlibroService.parsePrices(html: "").isEmpty)
    }

    func test_parsePrices_noListings_returnsEmpty() {
        let html = "<html><body>No items found</body></html>"
        XCTAssertTrue(IberlibroService.parsePrices(html: html).isEmpty)
    }
}
