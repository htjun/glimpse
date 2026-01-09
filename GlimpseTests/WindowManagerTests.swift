//
//  WindowManagerTests.swift
//  GlimpseTests
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import Foundation
import Testing
@testable import Glimpse

// MARK: - Mock Window

@MainActor
final class MockWindow: WindowProtocol {
    var isVisible: Bool = false
    var makeKeyAndOrderFrontCalled = false
    var closeCalled = false

    func makeKeyAndOrderFront(_ sender: Any?) {
        makeKeyAndOrderFrontCalled = true
        isVisible = true
    }

    func close() {
        closeCalled = true
        isVisible = false
    }

    func reset() {
        isVisible = false
        makeKeyAndOrderFrontCalled = false
        closeCalled = false
    }
}

// MARK: - Tests

@MainActor
struct WindowManagerTests {

    // MARK: - Setup

    private func createWindowManager() -> WindowManager {
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: {}
        )
        return manager
    }

    // MARK: - registerWindow Tests

    @Test func registerWindowStoresReference() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()

        manager.registerWindow(mockWindow)

        #expect(manager.window != nil)
    }

    // MARK: - togglePanel Tests

    @Test func togglePanelOpensWindowWhenClosed() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()
        mockWindow.isVisible = false

        manager.registerWindow(mockWindow)
        manager.togglePanel()

        #expect(mockWindow.makeKeyAndOrderFrontCalled == true)
        #expect(mockWindow.isVisible == true)
    }

    @Test func togglePanelClosesWindowWhenOpen() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()
        mockWindow.isVisible = true

        manager.registerWindow(mockWindow)
        manager.togglePanel()

        #expect(mockWindow.closeCalled == true)
        #expect(mockWindow.isVisible == false)
    }

    @Test func togglePanelPostsNotificationWhenNoWindow() async throws {
        let manager = createWindowManager()
        var notificationReceived = false

        let observer = NotificationCenter.default.addObserver(
            forName: .shouldOpenTranslationPanel,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }

        // Ensure no window is registered
        manager.reset()

        manager.togglePanel()

        // Give notification time to be delivered
        try await Task.sleep(for: .milliseconds(50))

        #expect(notificationReceived == true)

        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - closePanel Tests

    @Test func closePanelClosesRegisteredWindow() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()
        mockWindow.isVisible = true

        manager.registerWindow(mockWindow)
        manager.closePanel()

        #expect(mockWindow.closeCalled == true)
    }

    @Test func closePanelDoesNothingWhenNoWindow() async throws {
        let manager = createWindowManager()

        // Should not crash when no window is registered
        manager.reset()
        manager.closePanel()

        // Test passes if no crash occurs
        #expect(true)
    }

    // MARK: - reset Tests

    @Test func resetClearsWindowReference() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()

        manager.registerWindow(mockWindow)
        #expect(manager.window != nil)

        manager.reset()
        #expect(manager.window == nil)
        #expect(manager.panelWindow == nil)
    }

    // MARK: - activateApp Tests

    @Test func togglePanelCallsActivateAppWhenOpening() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        let mockWindow = MockWindow()
        mockWindow.isVisible = false

        manager.registerWindow(mockWindow)
        manager.togglePanel()

        #expect(activateCalled == true)
    }
}
