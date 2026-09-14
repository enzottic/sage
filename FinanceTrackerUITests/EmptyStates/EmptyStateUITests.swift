import XCTest

@MainActor
final class EmptyStateUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    func testCategoryEmptyActionPreservesCategoryAndMonthWhenSaving() {
        let app = launch()
        app.buttons["Previous Month"].tap()
        capture("Empty dashboard", app)
        let category = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Wants,")).firstMatch
        reveal(category, in: app)
        category.tap()
        let add = app.buttons["category-empty-add"]
        XCTAssertTrue(add.waitForExistence(timeout: timeout))
        capture("Empty category", app)
        add.tap()
        let name = app.textFields["expense-name-field"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        // Context alone is not an edit, so Cancel must dismiss without a discard alert.
        app.buttons["cancel-expense-button"].tap()
        XCTAssertTrue(name.waitForNonExistence(timeout: timeout))
        add.tap()
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: timeout))
        app.typeText("Empty State Purchase")
        app.textFields["expense-amount-field"].tap()
        app.typeText("1234")
        XCTAssertTrue(app.buttons["expense-category-wants"].isSelected)
        app.buttons["expense-category-wants"].tap()
        capture("Category expense draft", app)
        app.buttons["save-expense-button"].tap()
        XCTAssertTrue(name.waitForNonExistence(timeout: timeout))
        XCTAssertFalse(add.exists)
        // Appearing in the same category/month proves both draft defaults survived saving.
        XCTAssertTrue(app.staticTexts["Empty State Purchase"].firstMatch.waitForExistence(timeout: timeout))
        capture("Category populated after save", app)
    }

    func testEmptyDashboardAndMonthActionsAndWidgetExplanation() {
        let app = launch(arguments: ["-appearance", "Dark", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXL"])
        let dashboardAdd = app.buttons["dashboard-empty-add"]
        reveal(dashboardAdd, in: app)
        dashboardAdd.tap()
        XCTAssertTrue(app.textFields["expense-name-field"].waitForExistence(timeout: timeout))
        app.buttons["cancel-expense-button"].tap()
        app.swipeDown()
        app.buttons["dashboard-options"].tap()
        app.buttons["Reorder Widgets"].tap()
        let explanation = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "These widgets keep their positions while hidden.")).firstMatch
        reveal(explanation, in: app)
        capture("Hidden widget explanation", app)
        app.buttons["Done"].tap()
        app.tabBars.buttons["Expenses"].tap()
        XCTAssertTrue(app.staticTexts["No expenses for this month"].waitForExistence(timeout: timeout))
        capture("Empty expenses month", app)
        let add = app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "Add Expense", "add-expense-button")).firstMatch
        add.tap()
        XCTAssertTrue(app.textFields["expense-name-field"].waitForExistence(timeout: timeout))
        app.buttons["cancel-expense-button"].tap()
    }

    func testEmptySettingsActionsOpenTagAndRecurringForms() {
        let app = launch()
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Tags"].tap()
        let addTag = app.buttons["tags-empty-add"]
        XCTAssertTrue(addTag.waitForExistence(timeout: timeout))
        capture("Empty tags", app)
        addTag.tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: timeout))
        app.buttons["Cancel"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Recurring Expenses"].tap()
        let addRecurring = app.buttons["Add Recurring Expense"]
        XCTAssertTrue(addRecurring.waitForExistence(timeout: timeout))
        capture("Empty recurring expenses", app)
        addRecurring.tap()
        XCTAssertTrue(app.textFields["expense-name-field"].waitForExistence(timeout: timeout))
        app.swipeUp()
        let recurring = app.switches["Recurring"]
        reveal(recurring, in: app)
        XCTAssertEqual(recurring.value as? String, "1")
        capture("Recurring expense draft", app)
        app.buttons["cancel-expense-button"].tap()
        XCTAssertTrue(app.textFields["expense-name-field"].waitForNonExistence(timeout: timeout))
    }

    private func launch(arguments: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchArguments += arguments
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons["dashboard-options"].waitForExistence(timeout: timeout))
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
