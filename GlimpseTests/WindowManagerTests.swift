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
        #expect(activateCalled == false) // No window, so app not activated directly
        #expect(manager.isPanelIntendedOpen == true)

        NotificationCenter.default.removeObserver(observer)
    }
}
