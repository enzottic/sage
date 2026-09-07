import XCTest

@MainActor
final class StatsViewUITests: XCTestCase {
    private let timeout: TimeInterval = 20
    private let calendar = Calendar.current

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMonthArrowsUpdateSpendingAndStopAtCurrentMonth() {
        let app = launchStats()
        let currentMonth = calendar.dateInterval(of: .month, for: Date())!.start
        assertMonth(currentMonth, total: "42.50", in: app)
        attachScreenshot(named: "Stats – current month", in: app)
        XCTAssertFalse(app.buttons["stats-next-month"].isEnabled)

        app.buttons["stats-previous-month"].tap()
        assertMonth(calendar.date(byAdding: .month, value: -1, to: currentMonth)!, total: "0.00", in: app)
        attachScreenshot(named: "Stats – previous month", in: app)
        XCTAssertTrue(app.buttons["stats-next-month"].isEnabled)

        app.buttons["stats-next-month"].tap()
        assertMonth(currentMonth, total: "42.50", in: app)
        XCTAssertFalse(app.buttons["stats-next-month"].isEnabled)
    }

    func testMonthChooserSelectsAnOlderMonthAndReturnsToThisMonth() {
        let app = launchStats()
        let currentMonth = calendar.dateInterval(of: .month, for: Date())!.start
        let olderMonth = calendar.date(byAdding: .month, value: -2, to: currentMonth)!

        openMonthChooser(in: app)
        let monthWheel = app.pickerWheels.element(boundBy: 0)
        let yearWheel = app.pickerWheels.element(boundBy: 1)
        XCTAssertTrue(monthWheel.waitForExistence(timeout: timeout))
        yearWheel.adjust(toPickerWheelValue: String(calendar.component(.year, from: olderMonth)))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM"
        monthWheel.adjust(toPickerWheelValue: formatter.string(from: olderMonth))
        attachScreenshot(named: "Stats – month chooser", in: app)
        app.buttons["Done"].tap()
        XCTAssertTrue(monthWheel.waitForNonExistence(timeout: timeout))
        assertMonth(olderMonth, total: "0.00", in: app)

        openMonthChooser(in: app)
        let thisMonth = app.buttons["This Month"]
        XCTAssertTrue(thisMonth.waitForExistence(timeout: timeout))
        thisMonth.tap()
        assertMonth(currentMonth, total: "42.50", in: app)
    }

    func testTappingMonthlyHistorySelectsTheMonthEvenWithNoSpending() {
        let app = launchStats()
        let currentMonth = calendar.dateInterval(of: .month, for: Date())!.start
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        tapPreviousMonthInHistory(in: app)
        assertMonth(previousMonth, total: "0.00", in: app)

        app.buttons["stats-next-month"].tap()
        assertMonth(currentMonth, total: "42.50", in: app)

        // Selecting the same bar again must still work after navigation changes the month.
        tapPreviousMonthInHistory(in: app)
        assertMonth(previousMonth, total: "0.00", in: app)
    }

    func testCategoryFilterExcludesExpenseAndAllCategoriesRestoresTotal() {
        let app = launchStats()
        let currentMonth = calendar.dateInterval(of: .month, for: Date())!.start

        assertMonth(currentMonth, total: "42.50", in: app)

        selectCategory("needs", in: app)
        assertMonth(currentMonth, total: "0.00", in: app)

        selectCategory("all", in: app)
        assertMonth(currentMonth, total: "42.50", in: app)
    }

    private func openMonthChooser(in app: XCUIApplication) {
        app.buttons["stats-filters"].tap()
        let chooseMonth = app.buttons["stats-choose-month"]
        XCTAssertTrue(chooseMonth.waitForExistence(timeout: timeout))
        attachScreenshot(named: "Stats - filters menu", in: app)
        chooseMonth.tap()
    }

    private func selectCategory(_ category: String, in app: XCUIApplication) {
        app.buttons["stats-filters"].tap()
        let submenu = app.buttons["Category"]
        XCTAssertTrue(submenu.waitForExistence(timeout: timeout))
        submenu.tap()
        let option = app.buttons["stats-category-\(category)"]
        XCTAssertTrue(option.waitForExistence(timeout: timeout))
        option.tap()
        XCTAssertTrue(option.waitForNonExistence(timeout: timeout))
    }

    private func tapPreviousMonthInHistory(in app: XCUIApplication) {
        let chart = app.descendants(matching: .any)
            .matching(identifier: "stats-history-chart").firstMatch
        let scrollView = app.scrollViews["stats-scroll-view"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: timeout))
        let viewport = scrollView.frame.intersection(app.windows.firstMatch.frame)
        for _ in 0..<6 {
            if chart.exists, !chart.frame.isEmpty, viewport.contains(chart.frame) { break }
            // Scroll along the card edge, away from the charts' interaction gestures.
            scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8))
                .press(forDuration: 0.01, thenDragTo: scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.25)))
        }
        // The chart is an accessibility container; its children, not the container, are actionable.
        XCTAssertTrue(chart.exists && !chart.frame.isEmpty && viewport.contains(chart.frame),
                      "The spending history chart did not become visible.\n\(app.debugDescription)")
        attachScreenshot(named: "Stats – monthly spending history", in: app)

        // The second-to-last slot is the prior month in the stable six-month window.
        // Tap inside its plot column to exercise the gesture, including zero-height bars.
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.77, dy: 0.5)).tap()
        for _ in 0..<6 {
            let total = app.staticTexts["stats-month-total"]
            if total.exists, total.isHittable, viewport.contains(total.frame) { break }
            scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.25))
                .press(forDuration: 0.01, thenDragTo: scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8)))
        }
    }

    private func attachScreenshot(named name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launchStats() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "0"
        app.launchEnvironment["SAGE_UI_TEST_SEED_EXPENSE"] = "Stats Seed Expense"
        app.launch()
        let statsTab = app.tabBars.buttons["Stats"]
        XCTAssertTrue(statsTab.waitForExistence(timeout: timeout))
        statsTab.tap()
        let filters = app.navigationBars.buttons["stats-filters"]
        XCTAssertTrue(filters.waitForExistence(timeout: timeout))
        XCTAssertEqual(filters.label, "Filters")
        return app
    }

    private func assertMonth(_ month: Date, total: String, in app: XCUIApplication,
                             file: StaticString = #filePath, line: UInt = #line) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        let expectedMonth = formatter.string(from: month)
        XCTAssertTrue(app.navigationBars.staticTexts[expectedMonth].waitForExistence(timeout: timeout),
                      "Expected month subtitle \(expectedMonth).", file: file, line: line)
        let displayedTotal = app.staticTexts["stats-month-total"]
        XCTAssertTrue(displayedTotal.waitForExistence(timeout: timeout), file: file, line: line)
        let totalMatches = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                displayedTotal.label.filter { $0.isNumber || $0 == "." } == total
            },
            object: displayedTotal
        )
        XCTAssertEqual(XCTWaiter.wait(for: [totalMatches], timeout: timeout), .completed,
                       "Expected total \(total), got \(displayedTotal.label).", file: file, line: line)
    }
}
