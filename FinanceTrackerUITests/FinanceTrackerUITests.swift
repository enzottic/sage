//
//  FinanceTrackerUITests.swift
//  FinanceTrackerUITests
//
//  Created by Tyler McCormick on 12/21/25.
//

import XCTest

final class FinanceTrackerUITests: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testWelcomeViewAppearsOnFirstLaunch() throws {
        // Given: App is launching for the first time
        let app = XCUIApplication()
        app.launchArguments.append("-hasOpenedAppOnce")
        app.launchArguments.append("false")

        // When: App is launched
        app.launch()

        // Then: Welcome view should be displayed
        let welcomeTitle = app.staticTexts["Welcome to Sage"]
        XCTAssertTrue(welcomeTitle.exists, "Welcome view title should be visible on first launch")

        // Verify the welcome screen has expected elements
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists, "Get Started button should be visible")

        let subtitle = app.staticTexts["Your Smart Budgeting Companion"]
        XCTAssertTrue(subtitle.exists, "Welcome subtitle should be visible")
    }

    @MainActor
    func testWelcomeViewDoesNotAppearAfterOnboarding() throws {
        // Given: App has been opened before
        let app = XCUIApplication()
        app.launchArguments.append("-hasOpenedAppOnce")
        app.launchArguments.append("true")

        // When: App is launched
        app.launch()

        // Then: Welcome view should NOT be displayed
        let welcomeTitle = app.staticTexts["Welcome to Sage"]
        XCTAssertFalse(welcomeTitle.exists, "Welcome view should not appear when app has been opened before")

        // Main app tab view should be visible instead
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2), "Main tab bar should be visible")
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
