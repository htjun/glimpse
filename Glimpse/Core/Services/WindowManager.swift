//
//  WindowManager.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
import os.log

/// Manages the translation panel window state.
@MainActor
final class WindowManager: NSObject, NSWindowDelegate {

    // MARK: - Singleton

    static let shared = WindowManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Glimpse", category: "WindowManager")

    /// Stored reference to the panel window (set by TranslationPanelView via WindowAccessor)
    private(set) var panelWindow: NSWindow?

    /// Internal window reference using protocol for testability
    private(set) var window: (any WindowProtocol)?

    /// Tracks the intended panel state
    private(set) var isPanelIntendedOpen: Bool = false

    /// Notification center (injectable for testing)
    var notificationCenter: NotificationCenter = .default

    /// Application activator (injectable for testing)
    var activateApp: () -> Void = {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    /// Internal initializer for testing
    init(notificationCenter: NotificationCenter = .default, activateApp: @escaping () -> Void = { NSApplication.shared.activate(ignoringOtherApps: true) }) {
        super.init()
        self.notificationCenter = notificationCenter
        self.activateApp = activateApp
    }

    // MARK: - Public Methods

    /// Register the panel window reference.
    /// When an NSWindow is provided, it also becomes the delegate.
    func registerWindow(_ window: any WindowProtocol) {
        self.window = window
        if let nsWindow = window as? NSWindow {
            panelWindow = nsWindow
            nsWindow.delegate = self
        }
        logger.debug("Panel window registered")
    }

    /// Toggle the translation panel visibility.
    /// Returns true if panel was opened, false if closed.
    @discardableResult
    func togglePanel() -> Bool {
        if isPanelIntendedOpen {
            closePanel()
            return false
        } else {
            openPanel()
            return true
        }
    }

    /// Opens the panel with focus.
    func openPanel() {
        isPanelIntendedOpen = true
        activateApp()

        if let window = window {
            window.makeKeyAndOrderFront(nil)
            logger.debug("Panel opened with focus")
        } else {
            notificationCenter.post(name: .shouldOpenTranslationPanel, object: nil)
            logger.debug("Posted notification to open panel (window not yet created)")
        }
    }

    /// Closes the panel.
    func closePanel() {
        isPanelIntendedOpen = false
        window?.close()
        logger.debug("Panel closed")
    }

    /// Reset state (for testing)
    func reset() {
        panelWindow = nil
        window = nil
        isPanelIntendedOpen = false
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        isPanelIntendedOpen = false
        logger.debug("Panel closed (detected via delegate)")
    }

    func windowDidBecomeKey(_ notification: Notification) {
        // Consume captured text and notify the panel
        if let text = TranslationViewModel.shared.consumeCapturedText() {
            notificationCenter.post(
                name: .didCapturePanelText,
                object: nil,
                userInfo: ["text": text]
            )
        }
        logger.debug("Panel became key")
    }
}
