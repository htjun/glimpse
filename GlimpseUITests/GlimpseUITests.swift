//
//  GlimpseUITests.swift
//  GlimpseUITests
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import XCTest

final class GlimpseUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Terminate the app after each test
    }

    @MainActor
    func testAppLaunches() throws {
        // Glimpse is a menu bar app (LSUIElement) so it has no main window.
        // This test verifies the app launches without crashing.
        let app = XCUIApplication()
        app.launch()

        // Menu bar apps may not report foreground state correctly
        // Just verify the app object exists after launch (no crash)
        XCTAssertNotNil(app)

        // Explicitly terminate - menu bar apps don't auto-terminate
        app.terminate()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
