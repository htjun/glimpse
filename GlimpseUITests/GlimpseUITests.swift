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

        // Terminate any existing instance first (e.g., if running in Xcode)
        app.terminate()

        // Launch and wait for the app to initialize
        app.launch()

        // Poll for app to reach a running state (menu bar apps need time to settle)
        let deadline = Date().addingTimeInterval(5.0)
        while Date() < deadline {
            if app.state == .runningForeground || app.state == .runningBackground {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        XCTAssertTrue(
            app.state == .runningForeground || app.state == .runningBackground,
            "App should be running after launch, but state is \(app.state.rawValue)"
        )

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
