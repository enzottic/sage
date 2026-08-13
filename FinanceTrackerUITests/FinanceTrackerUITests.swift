//
//  FinanceTrackerUITests.swift
//  FinanceTrackerUITests
//
//  Created by Tyler McCormick on 12/21/25.
//

import XCTest

final class FinanceTrackerUITests: XCTestCase {

    private let elementTimeout: TimeInterval = 10

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    private func launchApp(hasOpenedAppOnce: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasOpenedAppOnce",
            hasOpenedAppOnce ? "true" : "false"
        ]
        app.launch()

        let whatsNewTitle = app.staticTexts["What's New"]
        if whatsNewTitle.waitForExistence(timeout: 2) {
            let continueButton = app.buttons["Continue"]
            XCTAssertTrue(
                continueButton.waitForExistence(timeout: elementTimeout),
                "What's New continue button should be visible"
            )
            continueButton.tap()
            XCTAssertTrue(
                whatsNewTitle.waitForNonExistence(timeout: elementTimeout),
                "What's New view should close"
            )
        }

        return app
    }

    @MainActor
    func testWelcomeViewAppearsOnFirstLaunch() throws {
        let app = launchApp(hasOpenedAppOnce: false)

        let welcomeTitle = app.staticTexts["Welcome to Sage"]
        XCTAssertTrue(
            welcomeTitle.waitForExistence(timeout: elementTimeout),
            "Welcome view title should be visible on first launch"
        )

        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(
            getStartedButton.waitForExistence(timeout: elementTimeout),
            "Get Started button should be visible"
        )
    }

    @MainActor
    func testWelcomeViewDoesNotAppearAfterOnboarding() throws {
        let app = launchApp(hasOpenedAppOnce: true)

        let welcomeTitle = app.staticTexts["Welcome to Sage"]
        XCTAssertFalse(welcomeTitle.exists, "Welcome view should not appear when app has been opened before")

        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(
            homeTab.waitForExistence(timeout: elementTimeout),
            "Main tab bar should be visible"
        )
    }

    @MainActor
    func testCanAddExpenseAndPersists() {
        let expenseName = "UI Test Expense"
        let app = launchApp(hasOpenedAppOnce: true)

        let addButton = app.buttons["Add Expense"].firstMatch
        XCTAssertTrue(
            addButton.waitForExistence(timeout: elementTimeout),
            "Add expense button should be visible"
        )
        addButton.tap()

        let nameField = app.textFields["New Expense"].firstMatch
        XCTAssertTrue(
            nameField.waitForExistence(timeout: elementTimeout),
            "Expense name field should be visible"
        )
        nameField.tap()
        nameField.typeText(expenseName)

        let amountField = app.textFields["$0.00"].firstMatch
        XCTAssertTrue(
            amountField.waitForExistence(timeout: elementTimeout),
            "Expense amount field should be visible"
        )
        amountField.tap()
        amountField.typeText("1234")

        let saveButton = app.buttons["Save"].firstMatch
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: elementTimeout),
            "Save button should be visible"
        )
        saveButton.tap()

        let newExpenseNavigationBar = app.navigationBars["New Expense"]
        XCTAssertTrue(
            newExpenseNavigationBar.waitForNonExistence(timeout: elementTimeout),
            "New expense view should close after save"
        )

        app.terminate()
        app.launch()

        let expensesTab = app.tabBars.buttons["Expenses"]
        XCTAssertTrue(
            expensesTab.waitForExistence(timeout: elementTimeout),
            "Expenses tab should be visible"
        )
        expensesTab.tap()

        let savedExpense = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", expenseName)
        ).firstMatch
        XCTAssertTrue(
            savedExpense.waitForExistence(timeout: elementTimeout),
            "Saved expense should remain after relaunch"
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
