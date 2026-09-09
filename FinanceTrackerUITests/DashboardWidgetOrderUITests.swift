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
        let needs = app.staticTexts["Needs"].firstMatch
        XCTAssertLessThan(overview.frame.minY, needs.frame.minY)
        let reset = app.buttons["Reset to Default"]
        XCTAssertFalse(reset.isEnabled)
        capture("Widget order before drag", app)

        app.buttons["Reorder Monthly Overview"].press(
            forDuration: 1,
            thenDragTo: app.buttons["Reorder Needs"],
            withVelocity: .slow,
            thenHoldForDuration: 1
        )
        XCTAssertLessThan(needs.frame.minY, overview.frame.minY)
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
        }
        capture("Dashboard after reordering", app)

        openSheet(app)
        XCTAssertLessThan(needs.frame.minY, overview.frame.minY)
        reset.tap()
        XCTAssertLessThan(overview.frame.minY, needs.frame.minY)
        app.buttons["Undo Reset"].tap()
        XCTAssertLessThan(needs.frame.minY, overview.frame.minY)
        app.buttons["Sheet Grabber"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
        XCTAssertTrue(app.navigationBars["Reorder Widgets"].waitForNonExistence(timeout: 10))

        openSheet(app)
        XCTAssertLessThan(needs.frame.minY, overview.frame.minY)
        reset.tap()
        app.buttons["Done"].tap()
        capture("Dashboard after reset", app)
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
