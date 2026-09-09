import XCTest
import UIKit

@MainActor
final class DashboardWidgetOrderUITests: XCTestCase {
    func testDragPersistsAcrossDismissalAndResetCanBeUndone() {
        continueAfterFailure = false
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if isPad { XCUIDevice.shared.orientation = .landscapeLeft }
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "0"
        app.launch()

        openSheet(app)
        let overview = app.staticTexts["Monthly Overview"]
        let categories = app.staticTexts["Categories"].firstMatch
        XCTAssertFalse(app.buttons["Reorder Needs"].exists)
        XCTAssertFalse(app.buttons["Reorder Wants"].exists)
        XCTAssertFalse(app.buttons["Reorder Savings"].exists)
        XCTAssertLessThan(overview.frame.minY, categories.frame.minY)
        let reset = app.buttons["Reset to Default"]
        XCTAssertFalse(reset.isEnabled)
        capture("Widget order before drag", app)

        app.buttons["Reorder Monthly Overview"].press(
            forDuration: 1,
            thenDragTo: app.buttons["Reorder Categories"],
            withVelocity: .slow,
            thenHoldForDuration: 1
        )
        XCTAssertLessThan(categories.frame.minY, overview.frame.minY)
        XCTAssertTrue(reset.isEnabled)
        capture("Widget order after drag", app)
        app.buttons["Done"].tap()
        if isPad {
            let needsCard = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Needs,")).firstMatch
            let wantsCard = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Wants,")).firstMatch
            let totalSpent = app.staticTexts["Total Spent"].firstMatch
            XCTAssertTrue(needsCard.waitForExistence(timeout: 10))
            XCTAssertLessThan(needsCard.frame.minX, totalSpent.frame.minX)
            XCTAssertLessThan(needsCard.frame.minY, wantsCard.frame.minY)
            assertEqualCardSizes(app, ids: ["categories", "monthlyOverview"])
            assertCategoryStack(app)
        }
        capture("Dashboard after reordering", app)

        openSheet(app)
        XCTAssertLessThan(categories.frame.minY, overview.frame.minY)
        reset.tap()
        XCTAssertLessThan(overview.frame.minY, categories.frame.minY)
        app.buttons["Undo Reset"].tap()
        XCTAssertLessThan(categories.frame.minY, overview.frame.minY)
        app.buttons["Sheet Grabber"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
        XCTAssertTrue(app.navigationBars["Reorder Widgets"].waitForNonExistence(timeout: 10))

        openSheet(app)
        XCTAssertLessThan(categories.frame.minY, overview.frame.minY)
        reset.tap()
        app.buttons["Done"].tap()
        capture("Dashboard after reset", app)
    }

    func testSeparateCategoriesNavigateAndIPadRowsAlignAfterRotation() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_SEED_CALENDAR"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_SEED_SEARCH"] = "1"
        app.launch()
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        defer { XCUIDevice.shared.orientation = .portrait }

        for category in ["Needs", "Wants", "Savings"] {
            let button = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "\(category),")).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 10))
            if !button.isHittable { app.swipeUp() }
            button.tap()
            XCTAssertTrue(app.navigationBars[category].waitForExistence(timeout: 10))
            app.navigationBars[category].buttons["BackButton"].tap()
            XCTAssertTrue(app.buttons["dashboard-options"].waitForExistence(timeout: 10))
        }

        if isPad {
            assertDashboardRows(app)
            capture("iPad portrait category stack", app)
            XCUIDevice.shared.orientation = .landscapeLeft
            assertDashboardRows(app)
            capture("iPad landscape category stack", app)
        } else {
            XCTAssertFalse(app.staticTexts["Categories"].exists)
            capture("iPhone separate category cards", app)
        }
    }

    private func assertDashboardRows(_ app: XCUIApplication) {
        assertEqualCardSizes(app, ids: ["monthlyOverview", "categories"])
        assertEqualCardSizes(app, ids: ["expenseCalendar", "recentExpenses"])
        assertCategoryStack(app)
        let overview = app.otherElements["dashboard-widget-monthlyOverview"].firstMatch.frame
        let calendar = app.otherElements["dashboard-widget-expenseCalendar"].firstMatch.frame
        XCTAssertLessThan(overview.height, calendar.height)
        XCTAssertEqual(calendar.minY - overview.maxY, 16, accuracy: 1)
    }

    private func assertCategoryStack(_ app: XCUIApplication) {
        let stack = app.otherElements["dashboard-widget-categories"].firstMatch.frame
        let cards = ["Needs", "Wants", "Savings"].map {
            app.otherElements["dashboard-category-\($0)"].firstMatch
        }
        for card in cards { XCTAssertTrue(card.waitForExistence(timeout: 10)) }
        XCTAssertEqual(cards[0].frame.minY, stack.minY, accuracy: 1)
        XCTAssertEqual(cards[2].frame.maxY, stack.maxY, accuracy: 1)
        for index in 1..<cards.count {
            XCTAssertEqual(cards[index].frame.minY - cards[index - 1].frame.maxY, 12, accuracy: 1)
        }
    }

    private func assertEqualCardSizes(_ app: XCUIApplication, ids: [String]) {
        let cards = ids.map { app.otherElements["dashboard-widget-\($0)"].firstMatch }
        for card in cards { XCTAssertTrue(card.waitForExistence(timeout: 10)) }
        let size = cards[0].frame.size
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
        for card in cards.dropFirst() {
            XCTAssertEqual(card.frame.width, size.width, accuracy: 1)
            XCTAssertEqual(card.frame.height, size.height, accuracy: 1)
        }
    }

    private func openSheet(_ app: XCUIApplication) {
        let options = app.buttons["dashboard-options"]
        XCTAssertTrue(options.waitForExistence(timeout: 10))
        options.tap()
        app.buttons["Reorder Widgets"].tap()
        XCTAssertTrue(app.navigationBars["Reorder Widgets"].waitForExistence(timeout: 10))
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
