import XCTest

@MainActor
final class ExpenseBackupUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testBackupExportAndFilesCancellation() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["SAGE_UI_TESTING"] = "1"
        app.launchEnvironment["SAGE_UI_TEST_ONBOARDING"] = "0"
        app.launchEnvironment["SAGE_UI_TEST_SEED_EXPENSE"] = "Backup Seed"
        app.launch()
        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 20))
        settings.tap()
        let backup = app.buttons["Backup"].firstMatch
        XCTAssertTrue(backup.waitForExistence(timeout: 10))
        backup.tap()
        XCTAssertTrue(app.buttons["Create Expense Backup"].waitForExistence(timeout: 10))
        capture("Backup settings", app: app)
        app.buttons["Create Expense Backup"].tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Share or Save Export"].exists)
        dismissSavePicker(app)
        XCTAssertTrue(app.buttons["Create Expense Backup"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Could Not Complete"].exists)
        app.buttons["Create Expense Backup"].tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 10))
        let filenameField = app.textFields.firstMatch
        XCTAssertTrue(filenameField.waitForExistence(timeout: 10))
        let caption = try XCTUnwrap(filenameField.value as? String)
        capture("Save JSON to Files", app: app)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Import File"].waitForExistence(timeout: 10))
        app.buttons["Import File"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        capture("Native Files picker", app: app)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Import File"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Could Not Complete"].exists)
        app.buttons["Import File"].tap()
        let file = app.cells.matching(NSPredicate(format: "label BEGINSWITH %@", caption)).firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 10), app.debugDescription)
        file.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
        XCTAssertTrue(app.navigationBars["Review Import"].waitForExistence(timeout: 10))
        let noChanges = app.staticTexts["All expenses are already present. Nothing will be saved."]
        for _ in 0..<5 where !noChanges.exists { app.swipeUp() }
        XCTAssertTrue(noChanges.exists)
        XCTAssertFalse(app.buttons["Add Missing Expenses"].exists)
        capture("All-skipped JSON review", app: app)
        app.buttons["Done"].tap()
        app.buttons["Export CSV"].tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 10))
        dismissSavePicker(app)
        XCTAssertTrue(app.buttons["Export CSV"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Could Not Complete"].exists)
    }

    private func dismissSavePicker(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
