import XCTest

@MainActor
final class WidgetGalleryUITests: XCTestCase {
    func testWidgetGalleryOffersDailySpendingAndRetainedWidgets() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).press(forDuration: 2)
        let edit = springboard.buttons["Edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: 10), springboard.debugDescription)
        edit.tap()
        let addWidget = springboard.buttons["Add Widget"]
        XCTAssertTrue(addWidget.waitForExistence(timeout: 5), springboard.debugDescription)
        addWidget.tap()
        let search = springboard.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10), springboard.debugDescription)
        search.tap()
        search.typeText("Sage")
        let sage = springboard.cells["Sage"]
        XCTAssertTrue(sage.waitForExistence(timeout: 10), springboard.debugDescription)
        sage.tap()
        XCTAssertTrue(springboard.staticTexts["Daily Spending"].firstMatch.waitForExistence(timeout: 10), springboard.debugDescription)
        let screenshot = XCTAttachment(screenshot: springboard.screenshot())
        screenshot.name = "Daily Spending widget gallery"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let remainingPages = ["Recent Expenses", "Recent Expenses", "Category Spotlight",
                              "Monthly Summary", "Monthly Summary", "Monthly Summary"]
        for (index, title) in remainingPages.enumerated() {
            springboard.swipeLeft()
            XCTAssertTrue(springboard.staticTexts[title].firstMatch.waitForExistence(timeout: 5))
            let screenshot = XCTAttachment(screenshot: springboard.screenshot())
            screenshot.name = "Widget gallery page \(index + 1)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCUIDevice.shared.press(.home)
    }
}
