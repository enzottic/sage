import XCTest

@MainActor
final class TagEditorUITests: XCTestCase {
    private let timeout: TimeInterval = 20

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTagControlsAndSavedSelection() {
        checkTagEditor(dark: false)
    }

    func testTagControlsInDarkModeWithLargeText() {
        checkTagEditor(dark: true)
    }

    private func checkTagEditor(dark: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "0"
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if dark {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        }
        app.launch()
        tap(app.tabBars.buttons["Settings"])
        tap(app.buttons["Appearance"])
        tap(app.buttons.containing(.staticText, identifier: dark ? "Dark" : "Light").firstMatch)
        tap(app.navigationBars.buttons.firstMatch)
        let tags = app.buttons["Tags"]
        reveal(tags, in: app)
        tap(tags)
        tap(app.buttons["Add new tag"])

        let glyph = app.buttons["Choose tag icon"]
        XCTAssertTrue(glyph.waitForExistence(timeout: timeout))
        XCTAssertFalse((glyph.value as? String ?? "").isEmpty)
        XCTAssertGreaterThanOrEqual(glyph.frame.width, 44)
        XCTAssertGreaterThanOrEqual(glyph.frame.height, 44)
        screenshot("Tag editor - medium sheet", in: app)
        // Expand the sheet before walking every palette cell.
        app.swipeUp()
        let colors = ["Red", "Orange", "Yellow", "Green", "Mint", "Teal", "Blue", "Indigo", "Purple", "Pink"]
        var previous: XCUIElement?
        for name in colors {
            let swatch = app.buttons["\(name) color"]
            reveal(swatch, in: app)
            XCTAssertGreaterThanOrEqual(swatch.frame.width, 44)
            XCTAssertGreaterThanOrEqual(swatch.frame.height, 44)
            // The corner is outside the visible 28-point circle, but inside its target.
            swatch.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
            XCTAssertTrue(swatch.isSelected, "\(name) must expose selection after an edge tap.")
            if let previous { XCTAssertFalse(previous.isSelected) }
            previous = swatch
        }
        screenshot("Tag editor - named palette selected", in: app)

        let custom = app.buttons["Custom color"]
        reveal(custom, in: app)
        tap(custom)
        let closeColorPicker = app.buttons.matching(NSPredicate(format: "label ==[c] %@ OR label == %@", "close", "Done")).firstMatch
        XCTAssertTrue(closeColorPicker.waitForExistence(timeout: timeout), app.debugDescription)
        screenshot("Tag editor - native custom color picker", in: app)
        tap(closeColorPicker)

        // Return to the top if larger text required scrolling through the palette.
        app.scrollViews.firstMatch.swipeDown()
        tap(glyph)
        XCTAssertTrue(app.navigationBars["Tag Icon"].waitForExistence(timeout: timeout))
        tap(app.segmentedControls.buttons["Icon"])
        tap(app.buttons["creditcard fill"])
        XCTAssertEqual(glyph.value as? String, "creditcard fill")

        let nameField = app.textFields["Tag Name"]
        tap(nameField)
        nameField.typeText("Accessible Tag")
        tap(app.buttons["Add Tag"])
        let savedTag = app.buttons.containing(.staticText, identifier: "Accessible Tag").firstMatch
        reveal(savedTag, in: app)
        tap(savedTag)
        XCTAssertTrue(app.buttons["Pink color"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["Pink color"].isSelected, "Stored UIColor must match the original preset.")
        XCTAssertEqual(glyph.value as? String, "creditcard fill")
        screenshot("Tag editor - reopened saved selection", in: app)
        tap(app.buttons["cancel-tag-button"])
        XCTAssertTrue(glyph.waitForNonExistence(timeout: timeout), "An unchanged reopened tag should dismiss without confirmation.")
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable && app.windows.firstMatch.frame.contains(element.frame) { return }
            app.swipeUp()
        }
        XCTFail("Control is not reachable: \(element)\n\(app.debugDescription)")
    }

    private func tap(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
        element.tap()
    }

    private func screenshot(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
