//
//  WindowManagerTests.swift
//  GlimpseTests
//
import AppKit
import Foundation
import Testing
@testable import Glimpse

// MARK: - Tests

@MainActor
struct WindowManagerTests {

    // MARK: - Setup

    private func createWindowManager() -> WindowManager {
        WindowManager(notificationCenter: .default, activateApp: {})
    }

    // MARK: - togglePanel Tests

    @Test func togglePanelOpensWhenClosed() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )

        #expect(manager.isPanelIntendedOpen == false)

        let opened = manager.togglePanel()

        #expect(opened == true)
        #expect(activateCalled == true)
        #expect(manager.isPanelIntendedOpen == true)
    }

    @Test func togglePanelClosesWhenOpen() async throws {
        let manager = createWindowManager()

        // First toggle to open
        _ = manager.togglePanel()
        #expect(manager.isPanelIntendedOpen == true)

        // Second toggle to close
        let opened = manager.togglePanel()

        #expect(opened == false)
        #expect(manager.isPanelIntendedOpen == false)
    }

    // MARK: - openPanel Tests

    @Test func openPanelActivatesApp() async throws {
        var activateCalled = false
        let manager = WindowManager(
            notificationCenter: .default,
            activateApp: { activateCalled = true }
        )

        manager.openPanel()

        #expect(activateCalled == true)
        #expect(manager.isPanelIntendedOpen == true)
    }

    @Test func openPanelCreatesPanel() async throws {
        let manager = createWindowManager()

        #expect(manager.panel == nil)

        manager.openPanel()

        #expect(manager.panel != nil)
    }

    // MARK: - closePanel Tests

    @Test func closePanelUpdatesState() async throws {
        let manager = createWindowManager()

        manager.openPanel()
        #expect(manager.isPanelIntendedOpen == true)

        manager.closePanel()

        #expect(manager.isPanelIntendedOpen == false)
    }

    @Test func closePanelDoesNothingWhenAlreadyClosed() async throws {
        let manager = createWindowManager()

        // Should not crash when panel was never opened
        manager.closePanel()

        #expect(manager.isPanelIntendedOpen == false)
    }

    // MARK: - reset Tests

    @Test func resetClearsState() async throws {
        let manager = createWindowManager()

        manager.openPanel()
        #expect(manager.isPanelIntendedOpen == true)
        #expect(manager.panel != nil)

        manager.reset()

        #expect(manager.panel == nil)
        #expect(manager.isPanelIntendedOpen == false)
    }

    // MARK: - windowWillClose Tests

    @Test func windowWillCloseSyncsState() async throws {
        let manager = createWindowManager()

        manager.openPanel()
        #expect(manager.isPanelIntendedOpen == true)

        // Simulate external close via delegate
        let notification = Notification(name: NSWindow.willCloseNotification, object: nil)
        manager.windowWillClose(notification)

        #expect(manager.isPanelIntendedOpen == false)
    }

    @Test func hotkeyToggleWorksAfterExternalClose() async throws {
        let manager = createWindowManager()

        // Open panel via toggle
        let opened = manager.togglePanel()
        #expect(opened == true)
        #expect(manager.isPanelIntendedOpen == true)

        // Simulate external close via delegate
        let notification = Notification(name: NSWindow.willCloseNotification, object: nil)
        manager.windowWillClose(notification)
        #expect(manager.isPanelIntendedOpen == false)

        // Toggle again should open, not close
        let openedAgain = manager.togglePanel()
        #expect(openedAgain == true)
        #expect(manager.isPanelIntendedOpen == true)
    }
}
