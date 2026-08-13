import XCTest

@MainActor
final class FinanceTrackerUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsMainTabs() {
        let app = launchApp()

        XCTAssertTrue(
            app.tabBars.buttons["Expenses"].waitForExistence(timeout: timeout),
            "The main tab bar did not appear after launch."
        )
    }

    func testCompletesOnboarding() {
        let app = launchApp(showsOnboarding: true)

        let welcomeTitle = app.staticTexts["onboarding-welcome-title"]
        XCTAssertTrue(
            welcomeTitle.waitForExistence(timeout: timeout),
            "The welcome page did not appear for a clean onboarding launch."
        )

        tap("onboarding-get-started-button", in: app)

        let incomeField = app.textFields["onboarding-income-field"]
        XCTAssertTrue(incomeField.waitForExistence(timeout: timeout), "The income field did not appear.")
        incomeField.tap()
        incomeField.typeText("5000")

        let keyboardDone = app.buttons["onboarding-keyboard-done-button"]
        if keyboardDone.waitForExistence(timeout: 2) {
            keyboardDone.tap()
        }

        tap("onboarding-budget-continue-button", in: app)
        tap("onboarding-allocation-continue-button", in: app)
        tap("onboarding-sync-continue-button", in: app)
        tap("onboarding-tags-continue-button", in: app)
        tap("onboarding-start-tracking-button", in: app)

        XCTAssertTrue(
            app.tabBars.buttons["Expenses"].waitForExistence(timeout: timeout),
            "The main tabs did not appear after onboarding completed."
        )
    }

    func testAddsExpense() {
        let app = launchApp()
        openExpenses(in: app)

        addExpense(named: "Added Expense", amount: "12.34", in: app)

        XCTAssertTrue(
            expenseRow(named: "Added Expense", in: app).waitForExistence(timeout: timeout),
            "The saved expense did not appear in the expense list."
        )
    }

    func testEditsExpense() {
        let app = launchApp(seedExpense: "Expense to Edit")
        openExpenses(in: app)

        let originalRow = expenseRow(named: "Expense to Edit", in: app)
        XCTAssertTrue(originalRow.waitForExistence(timeout: timeout), "The seeded expense did not appear.")
        originalRow.tap()

        let nameField = app.textFields["expense-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: timeout), "The edit form did not appear.")
        nameField.clearAndTypeText("Edited Expense")
        tap("save-expense-changes-button", in: app)

        XCTAssertTrue(
            app.staticTexts["Edited Expense"].waitForExistence(timeout: timeout),
            "The edited expense name did not appear in the list."
        )
    }

    func testDuplicatesExpense() {
        let app = launchApp(seedExpense: "Expense to Duplicate")
        openExpenses(in: app)

        let originalRow = expenseRow(named: "Expense to Duplicate", in: app)
        XCTAssertTrue(originalRow.waitForExistence(timeout: timeout), "The seeded expense did not appear.")
        originalRow.swipeLeft()
        tap("duplicate-expense-action", in: app)

        let nameField = app.textFields["expense-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: timeout), "The duplicate form did not appear.")
        XCTAssertEqual(nameField.value as? String, "Expense to Duplicate")
        tap("save-expense-button", in: app)

        let duplicate = app.descendants(matching: .any)
            .matching(identifier: "expense-row-Expense to Duplicate")
            .element(boundBy: 1)
        XCTAssertTrue(duplicate.waitForExistence(timeout: timeout), "The duplicate expense did not appear.")
    }

    func testSearchesExpenses() {
        let app = launchApp(seedExpense: "Search Needle")
        openExpenses(in: app)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: timeout), "The expense search field did not appear.")
        searchField.tap()
        searchField.typeText("Needle")

        XCTAssertTrue(
            expenseRow(named: "Search Needle", in: app).waitForExistence(timeout: timeout),
            "The matching expense did not appear in search results."
        )
    }

    func testDeletesExpense() {
        let app = launchApp(seedExpense: "Expense to Delete")
        openExpenses(in: app)

        let row = expenseRow(named: "Expense to Delete", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: timeout), "The seeded expense did not appear.")
        row.swipeLeft()
        tap("delete-expense-action", in: app)
        tap("confirm-delete-expense-button", in: app)

        XCTAssertTrue(
            row.waitForNonExistence(timeout: timeout),
            "The deleted expense remained in the expense list."
        )
    }

    private func launchApp(showsOnboarding: Bool = false, seedExpense: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = showsOnboarding ? "1" : "0"
        if let seedExpense {
            app.launchEnvironment["SAGE_UI_TEST_SEED_EXPENSE"] = seedExpense
        }
        app.launch()
        return app
    }

    private func openExpenses(in app: XCUIApplication) {
        let expensesTab = app.tabBars.buttons["Expenses"]
        XCTAssertTrue(expensesTab.waitForExistence(timeout: timeout), "The Expenses tab did not appear.")
        expensesTab.tap()
    }

    private func addExpense(named name: String, amount: String, in app: XCUIApplication) {
        tap("add-expense-button", in: app)

        let nameField = app.textFields["expense-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: timeout), "The add expense form did not appear.")
        nameField.tap()
        nameField.typeText(name)

        let amountField = app.textFields["expense-amount-field"]
        XCTAssertTrue(amountField.waitForExistence(timeout: timeout), "The amount field did not appear.")
        amountField.tap()
        amountField.typeText(amount)

        tap("save-expense-button", in: app)
        XCTAssertTrue(
            nameField.waitForNonExistence(timeout: timeout),
            "The add expense form did not close after saving."
        )
    }

    private func expenseRow(named name: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "expense-row-\(name)").firstMatch
    }

    private func tap(_ identifier: String, in app: XCUIApplication) {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "The element '\(identifier)' did not appear.")
        XCTAssertTrue(element.isHittable, "The element '\(identifier)' was not hittable.")
        element.tap()
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        let currentText = value as? String ?? ""
        coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count))
        typeText(text)
    }
}
