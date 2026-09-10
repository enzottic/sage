import XCTest

@MainActor
final class ExpensesMonthPickerUITests: XCTestCase {
    private let timeout: TimeInterval = 20
    private let calendar = Calendar.current

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTitlePickerFiltersExpensesAndSupportsFutureYears() {
        let app = launchExpenses()
        let currentMonth = calendar.dateInterval(of: .month, for: Date())!.start
        let olderMonth = calendar.date(byAdding: .year, value: -1, to: currentMonth)!
        let futureMonth = calendar.date(byAdding: .year, value: 1, to: currentMonth)!
        let expense = app.staticTexts["Month Picker Expense"]
        XCTAssertTrue(expense.waitForExistence(timeout: timeout))
        screenshot("Expenses month title", in: app)

        openPicker(in: app)
        selectMonth(olderMonth, in: app)
        screenshot("Expenses month picker", in: app)
        app.buttons["Done"].tap()
        assertMonth(olderMonth, in: app)
        XCTAssertTrue(app.staticTexts["No expenses for this month"].waitForExistence(timeout: timeout))
        XCTAssertFalse(expense.exists)

        openPicker(in: app)
        assertPickerMonth(olderMonth, in: app)
        selectMonth(futureMonth, in: app)
        XCTAssertTrue(app.buttons["Done"].isEnabled)
        app.buttons["Done"].tap()
        assertMonth(futureMonth, in: app)

        app.buttons["Previous Month"].tap()
        assertMonth(calendar.date(byAdding: .month, value: -1, to: futureMonth)!, in: app)
        app.buttons["Next Month"].tap()
        assertMonth(futureMonth, in: app)

        openPicker(in: app)
        assertPickerMonth(futureMonth, in: app)
        app.buttons["This Month"].tap()
        assertMonth(currentMonth, in: app)
        XCTAssertTrue(expense.waitForExistence(timeout: timeout))
    }

    func testCancelAndSwipeDismissDiscardMonthChanges() {
        let app = launchExpenses()
        let currentMonth = calendar.dateInterval(of: .month, for: Date())!.start
        let olderMonth = calendar.date(byAdding: .month, value: -2, to: currentMonth)!

        openPicker(in: app)
        selectMonth(olderMonth, in: app)
        app.buttons["Cancel"].tap()
        assertMonth(currentMonth, in: app)

        openPicker(in: app)
        assertPickerMonth(currentMonth, in: app)
        selectMonth(olderMonth, in: app)
        let navigationBar = app.navigationBars["Choose Month"]
        navigationBar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(
                forDuration: 0.05,
                thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
            )
        assertMonth(currentMonth, in: app)

        openPicker(in: app)
        assertPickerMonth(currentMonth, in: app)
        app.buttons["Cancel"].tap()
    }

    private func launchExpenses() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "0"
        app.launchEnvironment["SAGE_UI_TEST_SEED_EXPENSE"] = "Month Picker Expense"
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Expenses"].waitForExistence(timeout: timeout))
        app.tabBars.buttons["Expenses"].tap()
        return app
    }

    private func openPicker(in app: XCUIApplication) {
        let title = app.buttons.matching(identifier: "expenses-month-picker").firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        XCTAssertEqual(app.buttons.matching(identifier: "expenses-month-picker").count, 1)
        title.tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: timeout))
    }

    private func selectMonth(_ date: Date, in app: XCUIApplication) {
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: String(calendar.component(.year, from: date)))
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: monthName(date))
    }

    private func assertPickerMonth(_ date: Date, in app: XCUIApplication) {
        XCTAssertEqual(app.pickerWheels.element(boundBy: 0).value as? String, monthName(date))
        XCTAssertEqual(app.pickerWheels.element(boundBy: 1).value as? String, String(calendar.component(.year, from: date)))
    }

    private func assertMonth(_ date: Date, in app: XCUIApplication) {
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForNonExistence(timeout: timeout))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        let title = app.buttons.matching(identifier: "expenses-month-picker").firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        XCTAssertEqual(title.label, formatter.string(from: date))
    }

    private func monthName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }

    private func screenshot(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
