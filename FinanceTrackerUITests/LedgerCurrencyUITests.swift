import XCTest

@MainActor
final class LedgerCurrencyUITests: XCTestCase {
    private let timeout: TimeInterval = 20

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testChangingAndCancellingCurrencyPreservesExpenseAmount() {
        checkCurrencyChange(dark: false)
    }

    func testCurrencyChangeInDarkModeWithLargeText() {
        checkCurrencyChange(dark: true)
    }

    private func checkCurrencyChange(dark: Bool) {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if dark { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXL"] }
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "0"
        app.launchEnvironment["SAGE_UI_TEST_SEED_EXPENSE"] = "Currency Seed"
        app.launch()

        tap(app.tabBars.buttons["Settings"])
        tap(app.buttons["Appearance"])
        tap(app.buttons.containing(.staticText, identifier: dark ? "Dark" : "Light").firstMatch)
        tap(app.navigationBars.buttons.firstMatch)
        assertSeedAmount(currency: "USD", in: app)
        tap(app.tabBars.buttons["Settings"])
        tap(app.buttons["Budget and Allocation"])
        let picker = app.buttons["ledger-currency-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: timeout))
        XCTAssertEqual(picker.value as? String, "USD")

        tap(picker)
        selectEuro(in: app)
        let confirmation = app.alerts["Change Ledger Currency?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: timeout))
        XCTAssertTrue(confirmation.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "All amounts stay unchanged.")
        ).firstMatch.exists)
        attachScreenshot("Currency confirmation", in: app)
        tap(confirmation.buttons["Cancel"])
        XCTAssertTrue(confirmation.waitForNonExistence(timeout: timeout))
        XCTAssertEqual(picker.value as? String, "USD", "Cancelling must not change the ledger currency.")
        assertSeedAmount(currency: "USD", in: app)

        tap(app.tabBars.buttons["Settings"])
        tap(picker)
        selectEuro(in: app)
        tap(confirmation.buttons["Change Currency"])
        XCTAssertTrue(confirmation.waitForNonExistence(timeout: timeout))
        XCTAssertEqual(picker.value as? String, "EUR")
        assertSeedAmount(currency: "EUR", in: app)

        tap(app.tabBars.buttons["Settings"])
        tap(app.navigationBars.buttons.firstMatch)
        tap(app.buttons["Budget and Allocation"])
        XCTAssertEqual(picker.value as? String, "EUR", "Reopening Settings must retain the confirmed currency.")
        attachScreenshot("Updated currency settings", in: app)
    }

    private func selectEuro(in app: XCUIApplication) {
        let option = app.buttons["ledger-currency-EUR"]
        let menu = app.collectionViews.element(boundBy: app.collectionViews.count - 1)
        XCTAssertTrue(menu.waitForExistence(timeout: timeout))
        for _ in 0..<25 {
            if option.exists && option.isHittable { break }
            menu.swipeDown()
        }
        tap(option)
    }

    private func attachScreenshot(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertSeedAmount(currency: String, in app: XCUIApplication) {
        tap(app.tabBars.buttons["Expenses"])
        let row = app.descendants(matching: .any)
            .matching(identifier: "expense-row-Currency Seed").firstMatch
        tap(row)
        let amount = app.textFields["expense-amount-field"]
        XCTAssertTrue(amount.waitForExistence(timeout: timeout))
        let expected = 42.50.formatted(.currency(code: currency).locale(Locale(identifier: "en_US")))
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expected), object: amount
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed,
                       "Changing currency must relabel the existing 42.50 amount without conversion.")
        tap(app.buttons["back-expense-button"])
    }

    private func tap(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
        element.tap()
    }
}
