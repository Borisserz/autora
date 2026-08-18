import XCTest

final class AutoraUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSearchHubShowsListings() {
        let app = launch()
        let card = firstListingCard(in: app)
        XCTAssertTrue(card.waitForExistence(timeout: 8))
    }

    func testOpenListingShowsWrite() {
        let app = launch()
        tapListed(firstListingCard(in: app), in: app)
        XCTAssertTrue(app.buttons["autora.listing.write"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Br'")).firstMatch.exists)
    }

    func testFavoriteFromCardAppearsInTab() {
        let app = launch()
        let card = firstListingCard(in: app)
        XCTAssertTrue(card.waitForExistence(timeout: 8))
        app.swipeUp()
        let listingID = String(card.identifier.dropFirst("autora.listing.".count))
        let favorite = app.buttons["autora.listing.favorite.\(listingID)"]
        favorite.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.tabBars.buttons["autora.tab.favorites"].tap()
        XCTAssertTrue(app.buttons["autora.listing.\(listingID)"].waitForExistence(timeout: 8))
    }

    func testPostWizardPublishesListing() {
        let app = launch()
        app.tabBars.buttons["Объявления"].tap()
        let signIn = app.buttons["Войти"]
        if signIn.waitForExistence(timeout: 4) {
            signIn.tap()
        }
        let compose = app.buttons["autora.listings.new"]
        XCTAssertTrue(compose.waitForExistence(timeout: 6))
        compose.tap()
        let sheet = app.buttons["Подать объявление"]
        if sheet.waitForExistence(timeout: 2) {
            sheet.tap()
            compose.tap()
        }
        XCTAssertTrue(app.buttons["autora.wizard.testPhoto"].waitForExistence(timeout: 6))
        app.buttons["autora.wizard.testPhoto"].tap()
        app.buttons["autora.wizard.testDraft"].tap()
        let next = app.buttons["autora.wizard.next"]
        for _ in 0..<6 {
            XCTAssertTrue(next.waitForExistence(timeout: 4))
            next.tap()
        }
        XCTAssertTrue(app.staticTexts["Mazda 6"].waitForExistence(timeout: 8))
    }

    func testWriteRequiresSignInThenOpensChat() {
        let app = launch()
        tapListed(firstListingCard(in: app), in: app)
        let write = app.buttons["autora.listing.write"]
        XCTAssertTrue(write.waitForExistence(timeout: 8))
        write.tap()
        let login = app.alerts.buttons["Войти"]
        XCTAssertTrue(login.waitForExistence(timeout: 6))
        login.tap()
        write.tap()
        let field = app.textFields["autora.chat.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("тест")
        app.buttons["autora.chat.send"].tap()
        XCTAssertTrue(app.staticTexts["тест"].waitForExistence(timeout: 6))
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }

    private func firstListingCard(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "autora.listing.lst-")).firstMatch
    }

    private func tapListed(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 8))
        app.swipeUp()
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).tap()
    }
}
