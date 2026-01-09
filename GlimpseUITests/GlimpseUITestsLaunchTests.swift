//
//  GlimpseUITestsLaunchTests.swift
//  GlimpseUITests
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import XCTest

final class GlimpseUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false  // Menu bar apps don't have multiple UI configurations
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Glimpse is a menu bar app (LSUIElement) - verify it launches successfully
        // Menu bar apps run in background state since they have no main window
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }
}
