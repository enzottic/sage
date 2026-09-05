import XCTest

@MainActor
final class FinanceTrackerUITests: XCTestCase {
    private let timeout: TimeInterval = 20

    override func setUpWithError() throws {
        continueAfterFailure = false
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
        XCTAssertTrue(scrollToVisibility(of: incomeField, in: app))
        incomeField.tap()
        incomeField.typeText("5000")

        tap("onboarding-keyboard-done-button", in: app)

        tap("onboarding-budget-continue-button", in: app)
        tap("onboarding-allocation-continue-button", in: app)
        tap("onboarding-sync-continue-button", in: app)
        tap("onboarding-tags-continue-button", in: app)

        let planTotal = app.staticTexts["onboarding-plan-total"]
        XCTAssertTrue(planTotal.waitForExistence(timeout: timeout))
        XCTAssertTrue(scrollToVisibility(of: planTotal, in: app))
        let expectedTotal = Double(5000).formatted(
            .currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0))
        )
        XCTAssertEqual(planTotal.label, expectedTotal, "Income should be interpreted as whole currency units.")
        tap("onboarding-start-tracking-button", in: app)

        XCTAssertTrue(
            app.tabBars.buttons["Expenses"].waitForExistence(timeout: timeout),
            "The main tabs did not appear after onboarding completed."
        )
    }

    func testOnboardingIncomeKeyboardStaysOpenAndCanBeReopened() {
        let app = launchApp(showsOnboarding: true)
        tap("onboarding-get-started-button", in: app)

        let incomeField = app.textFields["onboarding-income-field"]
        XCTAssertTrue(incomeField.waitForExistence(timeout: timeout))
        incomeField.tap()

        // Tap software keys directly so typeText cannot recover lost field focus.
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: timeout))
        tap(keyboard.keys["5"], named: "5")
        tap(keyboard.keys["0"], named: "0")
        XCTAssertEqual(incomeField.value as? String, "50")
        XCTAssertTrue(keyboard.exists)

        tap("onboarding-keyboard-done-button", in: app)
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: timeout))
        incomeField.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(keyboard.waitForExistence(timeout: timeout))
        tap(keyboard.keys["0"], named: "0")
        XCTAssertEqual(incomeField.value as? String, "500")

        tap("onboarding-budget-continue-button", in: app)
        XCTAssertTrue(app.buttons["onboarding-allocation-continue-button"].waitForExistence(timeout: timeout))
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: timeout))
        tap("onboarding-back-button", in: app)
        XCTAssertEqual(incomeField.value as? String, "500")
    }

    func testOnboardingCurrencyDefaultsToRegionAndCanBeChangedWithIncome() {
        let app = XCUIApplication()
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "1"
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.launch()
        XCTAssertTrue(app.staticTexts["onboarding-welcome-title"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons["confirm-ledger-currency-button"].exists)
        tap("onboarding-get-started-button", in: app)

        let picker = app.buttons["onboarding-currency-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: timeout))
        XCTAssertEqual(picker.value as? String, "GBP")
        let incomeField = app.textFields["onboarding-income-field"]
        incomeField.tap()
        incomeField.typeText("5000")
        tap("onboarding-keyboard-done-button", in: app)
        XCTAssertTrue(scrollToVisibility(of: picker, in: app))
        picker.tap()
        tap("onboarding-currency-EUR", in: app)
        XCTAssertEqual(picker.value as? String, "EUR")
        tap("onboarding-budget-continue-button", in: app)
        tap("onboarding-back-button", in: app)
        XCTAssertEqual(picker.value as? String, "EUR")
        XCTAssertEqual(incomeField.value as? String, "5000")
        tap("onboarding-budget-continue-button", in: app)
        tap("onboarding-allocation-continue-button", in: app)
        tap("onboarding-sync-continue-button", in: app)
        tap("onboarding-tags-continue-button", in: app)
        let total = app.staticTexts["onboarding-plan-total"]
        XCTAssertTrue(total.waitForExistence(timeout: timeout))
        XCTAssertEqual(total.label, Double(5000).formatted(.currency(code: "EUR").locale(Locale(identifier: "en_GB")).precision(.fractionLength(0))))
    }

    func testOnboardingValidatesIncomeAndRetainsStateWhenGoingBack() {
        let app = launchApp(showsOnboarding: true)
        tap("onboarding-get-started-button", in: app)

        let incomeField = app.textFields["onboarding-income-field"]
        let budgetContinue = app.buttons["onboarding-budget-continue-button"]
        XCTAssertTrue(incomeField.waitForExistence(timeout: timeout))
        XCTAssertTrue(budgetContinue.waitForExistence(timeout: timeout))
        XCTAssertFalse(budgetContinue.isEnabled, "Empty income must not allow continuing.")
        XCTAssertTrue(scrollToVisibility(of: incomeField, in: app))
        incomeField.tap()
        incomeField.typeText("0")
        XCTAssertFalse(budgetContinue.isEnabled, "Zero income must not allow continuing.")
        incomeField.clearAndTypeText("5000")
        XCTAssertTrue(budgetContinue.isEnabled)
        incomeField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4))
        XCTAssertFalse(budgetContinue.isEnabled, "Clearing valid income must disable continuing again.")
        incomeField.typeText("5000")
        tap("onboarding-keyboard-done-button", in: app)
        tap("onboarding-budget-continue-button", in: app)
        tap("onboarding-allocation-continue-button", in: app)

        let syncToggle = app.switches["onboarding-sync-toggle"]
        XCTAssertTrue(syncToggle.waitForExistence(timeout: timeout))
        XCTAssertTrue(scrollToVisibility(of: syncToggle, in: app))
        XCTAssertEqual(syncToggle.value as? String, "0")
        tap(syncToggle, named: "onboarding-sync-toggle")
        XCTAssertEqual(syncToggle.value as? String, "1")
        tap("onboarding-sync-continue-button", in: app)

        let shoppingTag = app.buttons["onboarding-tag-Shopping"]
        XCTAssertTrue(shoppingTag.waitForExistence(timeout: timeout))
        XCTAssertTrue(scrollToVisibility(of: shoppingTag, in: app))
        XCTAssertFalse(shoppingTag.isSelected)
        tap(shoppingTag, named: "onboarding-tag-Shopping")
        XCTAssertTrue(shoppingTag.isSelected)
        tap("onboarding-tags-continue-button", in: app)
        XCTAssertTrue(app.buttons["onboarding-start-tracking-button"].waitForExistence(timeout: timeout))

        tap("onboarding-back-button", in: app)
        XCTAssertTrue(shoppingTag.waitForExistence(timeout: timeout))
        XCTAssertTrue(shoppingTag.isSelected, "Tag selection must survive returning from the summary.")
        tap("onboarding-back-button", in: app)
        XCTAssertTrue(syncToggle.waitForExistence(timeout: timeout))
        XCTAssertEqual(syncToggle.value as? String, "1", "Sync selection must survive going back.")
        tap("onboarding-back-button", in: app)
        XCTAssertTrue(app.buttons["onboarding-allocation-continue-button"].waitForExistence(timeout: timeout))
        tap("onboarding-back-button", in: app)
        XCTAssertTrue(incomeField.waitForExistence(timeout: timeout))
        XCTAssertEqual(incomeField.value as? String, "5000")
        XCTAssertTrue(budgetContinue.isEnabled)

        tap("onboarding-budget-continue-button", in: app)
        tap("onboarding-allocation-continue-button", in: app)
        XCTAssertTrue(syncToggle.waitForExistence(timeout: timeout))
        XCTAssertEqual(syncToggle.value as? String, "1")
        tap("onboarding-sync-continue-button", in: app)
        XCTAssertTrue(shoppingTag.waitForExistence(timeout: timeout))
        XCTAssertTrue(shoppingTag.isSelected, "Tag selection must also survive returning from earlier steps.")
    }

    func testOnboardingAllocationDividersSnapAndRetainBreakdown() {
        let app = launchApp(showsOnboarding: true)
        tap("onboarding-get-started-button", in: app)
        let incomeField = app.textFields["onboarding-income-field"]
        XCTAssertTrue(incomeField.waitForExistence(timeout: timeout))
        incomeField.tap()
        incomeField.typeText("5000")
        tap("onboarding-keyboard-done-button", in: app)
        tap("onboarding-budget-continue-button", in: app)

        let bar = app.descendants(matching: .any)["onboarding-allocation-bar"].firstMatch
        let needs = app.descendants(matching: .any)["onboarding-needs-divider"].firstMatch
        let savings = app.descendants(matching: .any)["onboarding-savings-divider"].firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: timeout))

        func assertBreakdown(_ needsValue: Int, _ wantsValue: Int, _ savingsValue: Int) {
            XCTAssertEqual(needs.value as? String, "Needs \(needsValue)%, Wants \(wantsValue)%")
            XCTAssertEqual(savings.value as? String, "Wants \(wantsValue)%, Savings \(savingsValue)%")
            XCTAssertEqual(needsValue + wantsValue + savingsValue, 100)
        }

        func drag(_ divider: XCUIElement, by percentage: Double) {
            let start = divider.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = start.withOffset(CGVector(dx: bar.frame.width * percentage / 100, dy: 0))
            start.press(forDuration: 0.1, thenDragTo: end)
        }

        assertBreakdown(50, 30, 20)
        let initial = XCTAttachment(screenshot: app.screenshot())
        initial.name = "Allocation - labeled bar"
        initial.lifetime = .keepAlways
        add(initial)

        drag(needs, by: 13)
        assertBreakdown(65, 15, 20)
        drag(savings, by: -8)
        assertBreakdown(65, 5, 30)
        drag(needs, by: 15)
        assertBreakdown(70, 0, 30)
        // Both handles must remain draggable even when the middle segment is collapsed.
        drag(savings, by: 10)
        assertBreakdown(70, 10, 20)
        drag(needs, by: -80)
        assertBreakdown(0, 80, 20)
        drag(needs, by: 35)
        assertBreakdown(35, 45, 20)
        drag(savings, by: 25)
        assertBreakdown(35, 65, 0)
        drag(savings, by: -20)
        assertBreakdown(35, 45, 20)

        tap("onboarding-allocation-continue-button", in: app)
        tap("onboarding-back-button", in: app)
        XCTAssertTrue(bar.waitForExistence(timeout: timeout))
        assertBreakdown(35, 45, 20)
        tap("onboarding-allocation-continue-button", in: app)
        tap("onboarding-sync-continue-button", in: app)
        tap("onboarding-tags-continue-button", in: app)
        XCTAssertTrue(app.staticTexts["onboarding-plan-total"].waitForExistence(timeout: timeout))
        let summary = XCTAttachment(screenshot: app.screenshot())
        summary.name = "Allocation - adjusted summary"
        summary.lifetime = .keepAlways
        add(summary)
    }

    func testOnboardingSupportsLargestAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "1"
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
        app.launch()

        let welcomeTitle = app.staticTexts["onboarding-welcome-title"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: timeout))

        let incomeField = app.textFields["onboarding-income-field"]
        let pages: [(String, XCUIElement)] = [
            ("onboarding-get-started-button", welcomeTitle),
            ("onboarding-budget-continue-button", incomeField),
            ("onboarding-allocation-continue-button", app.descendants(matching: .any)["onboarding-needs-divider"].firstMatch),
            ("onboarding-sync-continue-button", app.switches["onboarding-sync-toggle"]),
            ("onboarding-tags-continue-button", app.staticTexts["onboarding-tags-count"]),
            ("onboarding-start-tracking-button", app.staticTexts["onboarding-plan-total"])
        ]
        for (identifier, content) in pages {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.waitForExistence(timeout: timeout))
            XCTAssertTrue(content.waitForExistence(timeout: timeout))
            XCTAssertTrue(scrollToVisibility(of: content, in: app))
            if identifier == "onboarding-budget-continue-button" {
                tap(incomeField, named: "onboarding-income-field")
                incomeField.typeText("5000")
                tap("onboarding-keyboard-done-button", in: app)
            }
            XCTAssertTrue(app.windows.firstMatch.frame.contains(button.frame))
            if identifier != "onboarding-get-started-button" {
                let back = app.buttons["onboarding-back-button"]
                XCTAssertTrue(back.isHittable)
                XCTAssertEqual(back.frame.midY, button.frame.midY, accuracy: 2, "Back belongs beside Continue.")
            }
            XCTAssertTrue(button.isEnabled, "The primary action on \(identifier) must be enabled.")
            XCTAssertTrue(button.waitForHittability(timeout: timeout), "The primary action on \(identifier) must remain reachable.")

            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Largest text - \(identifier)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            button.tap()
        }

        XCTAssertTrue(app.tabBars.buttons["Expenses"].waitForExistence(timeout: timeout))
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

    func testShowAllRestoresMonthAndClearsDetail() {
        let app = launchApp(seedExpense: "Navigation Expense")
        let showAll = app.buttons["show-all-expenses-button"]
        XCTAssertTrue(scrollToVisibility(of: showAll, in: app))
        showAll.tap()
        XCTAssertTrue(app.tabBars.buttons["Expenses"].isSelected)
        let row = expenseRow(named: "Navigation Expense", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: timeout))

        tap("Previous Month", in: app)
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(scrollToVisibility(of: showAll, in: app))
        showAll.tap()
        XCTAssertTrue(row.waitForExistence(timeout: timeout))

        row.tap()
        XCTAssertTrue(app.textFields["expense-name-field"].waitForExistence(timeout: timeout))
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(scrollToVisibility(of: showAll, in: app))
        showAll.tap()
        XCTAssertTrue(row.waitForExistence(timeout: timeout))
        XCTAssertFalse(app.textFields["expense-name-field"].exists)
    }

    func testExpenseCalendarShowsDailySpendingAndChangesMonth() {
        let app = launchApp(seedExpense: "Calendar Expense")
        let calendar = Calendar.current
        let now = Date.now
        let dayNumber = calendar.component(.day, from: now)
        let today = app.descendants(matching: .any)["expense-calendar-day-\(dayNumber)"].firstMatch
        XCTAssertTrue(scrollToVisibility(of: today, in: app))
        XCTAssertEqual(today.value as? String, "\(42.50.formatted(.currency(code: "USD"))) spent, Today")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Expense calendar - current month"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        XCTAssertTrue(app.staticTexts["Expense Calendar"].exists)
        tap("Previous Month", in: app)
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let firstDay = app.descendants(matching: .any)["expense-calendar-day-1"].firstMatch
        let monthStart = calendar.dateInterval(of: .month, for: previousMonth)!.start
        XCTAssertEqual(firstDay.label, monthStart.formatted(date: .complete, time: .omitted))
        XCTAssertEqual(firstDay.value as? String, "\(Double(0).formatted(.currency(code: "USD"))) spent")
        tap("Next Month", in: app)
        XCTAssertEqual(today.value as? String, "\(42.50.formatted(.currency(code: "USD"))) spent, Today")
        XCTAssertFalse(app.buttons["Next Month"].isEnabled)

        openExpenses(in: app)
        addExpense(named: "Another Calendar Expense", amount: "12.34", in: app)
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(scrollToVisibility(of: today, in: app))
        XCTAssertEqual(today.value as? String, "\(54.84.formatted(.currency(code: "USD"))) spent, Today")
    }

    func testIPhoneStaysPortraitWhenDeviceRotates() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launchApp()
        openExpenses(in: app)
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            XCTAssertTrue(app.tabBars.buttons["Expenses"].waitForExistence(timeout: timeout))
            let frame = app.windows.firstMatch.frame
            XCTAssertLessThan(frame.width, frame.height)
            XCTAssertTrue(app.tabBars.buttons["Expenses"].isHittable)
        }
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

        // Swipe down so that the search bar is visible. Sometimes it gets hidden above the first expense in the list.
        app.swipeDown()

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

    func testDeletesDashboardExpense() {
        let app = launchApp(showsOnboarding: false, seedExpense: "Dashboard Expense to Delete")

        app.swipeUp()
        app.swipeUp()
        
        let row = expenseRow(named: "Dashboard Expense to Delete", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: timeout), "The dashboard expense did not appear.")
        
        revealDeleteAction(for: row)
        tap("delete-expense-action", in: app)
        tap("confirm-delete-expense-button", in: app)

        XCTAssertTrue(
            row.waitForNonExistence(timeout: timeout),
            "The deleted expense remained on the dashboard."
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
        let addButton = app.descendants(matching: .any)
            .matching(identifier: "add-expense-button")
            .firstMatch
        let nameField = app.textFields["expense-name-field"]

        tap(addButton, named: "add-expense-button")
        if !nameField.waitForExistence(timeout: timeout) {
            tap(addButton, named: "add-expense-button")
        }

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

    private func scrollToVisibility(of element: XCUIElement, in app: XCUIApplication) -> Bool {
        let window = app.windows.firstMatch
        for _ in 0..<10 {
            let frame = element.frame
            if window.exists,
               !frame.isNull,
               !frame.isEmpty,
               window.frame.contains(frame) {
                return true
            }
            app.swipeUp()
        }
        XCTFail("The element did not become visible.")
        return false
    }

    private func revealDeleteAction(for row: XCUIElement) {
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let end = row.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    private func tap(_ identifier: String, in app: XCUIApplication) {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        tap(element, named: identifier)
    }

    private func tap(_ element: XCUIElement, named identifier: String) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "The element '\(identifier)' did not appear.")
        XCTAssertTrue(
            element.waitForHittability(timeout: timeout),
            "The element '\(identifier)' was not hittable."
        )
        element.tap()
    }
}

private extension XCUIElement {
    func waitForHittability(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func clearAndTypeText(_ text: String) {
        let currentText = value as? String ?? ""
        coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count))
        typeText(text)
    }
}
