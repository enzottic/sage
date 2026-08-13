import XCTest

final class FinanceTrackerUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { true }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "0"
        app.launch()

        XCTAssertTrue(
            app.tabBars.buttons["Expenses"].waitForExistence(timeout: 10),
            "The main tabs did not appear after launch."
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Main Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
