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
    var orderFrontRegardlessCalled = false
    var closeCalled = false

    func makeKeyAndOrderFront(_ sender: Any?) {
        makeKeyAndOrderFrontCalled = true
        isVisible = true
    }

    func orderFrontRegardless() {
        orderFrontRegardlessCalled = true
        isVisible = true
    }

    func close() {
        closeCalled = true
        isVisible = false
    }

    func reset() {
        isVisible = false
        makeKeyAndOrderFrontCalled = false
        orderFrontRegardlessCalled = false
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
        let sessionID = manager.togglePanel()

        // Should use orderFrontRegardless (not makeKeyAndOrderFront) to avoid stealing focus
        #expect(mockWindow.orderFrontRegardlessCalled == true)
        #expect(mockWindow.isVisible == true)
        #expect(sessionID != nil)
        #expect(manager.isPanelIntendedOpen == true)
    }

    @Test func togglePanelClosesWindowWhenOpen() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()
        manager.registerWindow(mockWindow)

        // First toggle to open
        _ = manager.togglePanel()
        mockWindow.reset()

        // Second toggle to close
        let sessionID = manager.togglePanel()

        #expect(mockWindow.closeCalled == true)
        #expect(mockWindow.isVisible == false)
        #expect(sessionID == nil)
        #expect(manager.isPanelIntendedOpen == false)
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

        let sessionID = manager.togglePanel()

        // Give notification time to be delivered
        try await Task.sleep(for: .milliseconds(50))

        #expect(notificationReceived == true)
        #expect(sessionID != nil)

        NotificationCenter.default.removeObserver(observer)
    }

    @Test func togglePanelReturnsUniqueSessionIDs() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()
        manager.registerWindow(mockWindow)

        // Open -> Close -> Open should give different session IDs
        let session1 = manager.togglePanel()  // open
        _ = manager.togglePanel()              // close
        let session3 = manager.togglePanel()  // open

        #expect(session1 != nil)
        #expect(session3 != nil)
        #expect(session1 != session3)
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
        #expect(manager.isPanelIntendedOpen == false)
        #expect(manager.currentCaptureSessionID == nil)
    }

    // MARK: - Focus Behavior Tests

    @Test func togglePanelDoesNotActivateAppWhenOpening() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        let mockWindow = MockWindow()
        mockWindow.isVisible = false

        manager.registerWindow(mockWindow)
        manager.togglePanel()

        // Should NOT activate app - allows source app to keep focus for text capture
        #expect(activateCalled == false)
    }

    @Test func focusPanelActivatesAppAndMakesWindowKey() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        let mockWindow = MockWindow()

        manager.registerWindow(mockWindow)
        manager.focusPanel()

        // Should activate app AND make window key
        #expect(activateCalled == true)
        #expect(mockWindow.makeKeyAndOrderFrontCalled == true)
    }

    @Test func focusPanelDoesNothingWhenNoWindow() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )

        manager.reset()
        manager.focusPanel()

        // Should not activate app when no window
        #expect(activateCalled == false)
    }

    // MARK: - Session-Based Focus Tests

    @Test func focusPanelIfValidSucceedsWithValidSession() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        let mockWindow = MockWindow()
        manager.registerWindow(mockWindow)

        // Open and get session
        let sessionID = manager.togglePanel()!

        // Focus with valid session
        let result = manager.focusPanelIfValid(sessionID: sessionID)

        #expect(result == true)
        #expect(activateCalled == true)
        #expect(mockWindow.makeKeyAndOrderFrontCalled == true)
    }

    @Test func focusPanelIfValidIgnoresStaleSession() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        let mockWindow = MockWindow()
        manager.registerWindow(mockWindow)

        // Open and get session
        let sessionID = manager.togglePanel()!
        mockWindow.reset()

        // Close (invalidates session)
        _ = manager.togglePanel()
        mockWindow.reset()
        activateCalled = false

        // Try to focus with stale session
        let result = manager.focusPanelIfValid(sessionID: sessionID)

        #expect(result == false)
        #expect(activateCalled == false)
        #expect(mockWindow.makeKeyAndOrderFrontCalled == false)
    }

    @Test func focusPanelIfValidIgnoresWrongSession() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        let mockWindow = MockWindow()
        manager.registerWindow(mockWindow)

        // Open panel
        _ = manager.togglePanel()
        mockWindow.reset()

        // Try to focus with a random/wrong session ID
        let wrongSessionID = UUID()
        let result = manager.focusPanelIfValid(sessionID: wrongSessionID)

        #expect(result == false)
        #expect(activateCalled == false)
    }

    @Test func rapidToggleHandlesCorrectly() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()
        manager.registerWindow(mockWindow)

        // Rapid toggles: open -> close -> open
        let session1 = manager.togglePanel()  // open
        let session2 = manager.togglePanel()  // close
        let session3 = manager.togglePanel()  // open

        #expect(session1 != nil)
        #expect(session2 == nil)
        #expect(session3 != nil)
        #expect(session1 != session3)

        // Old session should be invalid
        #expect(manager.focusPanelIfValid(sessionID: session1!) == false)

        // New session should be valid
        #expect(manager.focusPanelIfValid(sessionID: session3!) == true)
    }
}
