import XCTest
@testable import BookChecker

final class TodocoleccionServiceTests: XCTestCase {

    func test_parsePrices_quijote_extractsOnlyCardPrices() throws {
        let html = try FixtureLoader.html("Resources/Todocoleccion/quijote.html")
        let prices = TodocoleccionService.parsePrices(html: html)

        // Should pull the 3 listing prices that the page renders (matches manual count).
        XCTAssertEqual(prices.count, 3)
        XCTAssertEqual(prices.min(), Decimal(string: "9.49"))
        XCTAssertEqual(prices.max(), Decimal(string: "11.39"))
    }

    func test_parsePrices_sample2_extractsOnlyCardPrices() throws {
        let html = try FixtureLoader.html("Resources/Todocoleccion/sample2.html")
        let prices = TodocoleccionService.parsePrices(html: html)

        XCTAssertEqual(prices.count, 3)
        XCTAssertEqual(prices.min(), Decimal(string: "4.99"))
    }

    func test_parsePrices_ignoresUnrelatedEuroAmounts() {
        // Only `card-price` spans count. A free `8,50 €` in the page body must not leak in.
        let html = """
        <div class="card-lote">
          <span class="card-price fs-18">9,99 €</span>
        </div>
        <p>Filtra por menos de 8,50 €</p>
        <span class="some-other-class">12,00 €</span>
        """
        let prices = TodocoleccionService.parsePrices(html: html)
        XCTAssertEqual(prices, [Decimal(string: "9.99")!])
    }

    func test_parsePrices_handlesWhitespaceVariants() {
        let html = """
        <span class="card-price">10,50  €</span>
        <span class="card-price">  7,25 €</span>
        """
        let prices = TodocoleccionService.parsePrices(html: html)
        XCTAssertEqual(Set(prices), Set([Decimal(string: "10.50")!, Decimal(string: "7.25")!]))
    }
}
