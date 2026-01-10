//
//  WindowManagerTests.swift
//  GlimpseTests
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
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

    /// Simulates an external close (ESC, Cmd+W, etc.) by notifying the delegate
    func simulateExternalClose(notifying delegate: NSWindowDelegate) {
        isVisible = false
        let notification = Notification(name: NSWindow.willCloseNotification, object: self)
        delegate.windowWillClose?(notification)
    }
}

// MARK: - Tests

@MainActor
struct WindowManagerTests {

    // MARK: - Setup

    private func createWindowManager() -> WindowManager {
        WindowManager(notificationCenter: .default, activateApp: {})
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
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        let mockWindow = MockWindow()
        mockWindow.isVisible = false

        manager.registerWindow(mockWindow)
        let opened = manager.togglePanel()

        // Should activate app and make window key
        #expect(activateCalled == true)
        #expect(mockWindow.makeKeyAndOrderFrontCalled == true)
        #expect(mockWindow.isVisible == true)
        #expect(opened == true)
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
        let opened = manager.togglePanel()

        #expect(mockWindow.closeCalled == true)
        #expect(mockWindow.isVisible == false)
        #expect(opened == false)
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

        let opened = manager.togglePanel()

        // Give notification time to be delivered
        try await Task.sleep(for: .milliseconds(50))

        #expect(notificationReceived == true)
        #expect(opened == true)

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
        #expect(manager.isPanelIntendedOpen == false)
    }

    // MARK: - openPanel Tests

    @Test func openPanelActivatesAppAndMakesWindowKey() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        let mockWindow = MockWindow()

        manager.registerWindow(mockWindow)
        manager.openPanel()

        #expect(activateCalled == true)
        #expect(mockWindow.makeKeyAndOrderFrontCalled == true)
        #expect(manager.isPanelIntendedOpen == true)
    }

    @Test func openPanelPostsNotificationWhenNoWindow() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )
        var notificationReceived = false

        let observer = NotificationCenter.default.addObserver(
            forName: .shouldOpenTranslationPanel,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }

        manager.reset()
        manager.openPanel()

        try await Task.sleep(for: .milliseconds(50))

        #expect(notificationReceived == true)
        #expect(activateCalled == true) // App is always activated to ensure focus on first launch
        #expect(manager.isPanelIntendedOpen == true)

        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - windowWillClose Tests

    @Test func externalWindowCloseSyncsState() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()

        manager.registerWindow(mockWindow)
        manager.openPanel()
        #expect(manager.isPanelIntendedOpen == true)

        // Simulate external close (e.g., ESC key, Cmd+W)
        mockWindow.simulateExternalClose(notifying: manager)

        #expect(manager.isPanelIntendedOpen == false)
    }

    @Test func hotkeyToggleWorksAfterExternalClose() async throws {
        let manager = createWindowManager()
        let mockWindow = MockWindow()

        manager.registerWindow(mockWindow)

        // Open panel via toggle
        let opened = manager.togglePanel()
        #expect(opened == true)
        #expect(manager.isPanelIntendedOpen == true)

        // Simulate external close (e.g., ESC)
        mockWindow.simulateExternalClose(notifying: manager)
        #expect(manager.isPanelIntendedOpen == false)

        mockWindow.reset()

        // Toggle again should open, not close
        let openedAgain = manager.togglePanel()
        #expect(openedAgain == true)
        #expect(mockWindow.makeKeyAndOrderFrontCalled == true)
        #expect(manager.isPanelIntendedOpen == true)
    }
}
