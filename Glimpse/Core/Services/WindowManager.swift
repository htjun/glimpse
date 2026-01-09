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
final class WindowManager {

    // MARK: - Singleton

    static let shared = WindowManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Glimpse", category: "WindowManager")

    /// Stored reference to the panel window (set by TranslationPanelView via WindowAccessor)
    private(set) var panelWindow: NSWindow?

    /// Internal window reference using protocol for testability
    private(set) var window: (any WindowProtocol)?

    /// Notification center (injectable for testing)
    var notificationCenter: NotificationCenter = .default

    /// Application activator (injectable for testing)
    var activateApp: () -> Void = {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - Initialization

    private init() {}

    /// Internal initializer for testing
    init(notificationCenter: NotificationCenter = .default, activateApp: @escaping () -> Void = { NSApplication.shared.activate(ignoringOtherApps: true) }) {
        self.notificationCenter = notificationCenter
        self.activateApp = activateApp
    }

    // MARK: - Public Methods

    /// Register the panel window reference (called by TranslationPanelView)
    func registerPanelWindow(_ window: NSWindow) {
        panelWindow = window
        self.window = window
        logger.debug("Panel window registered")
    }

    /// Register a window using the protocol (for testing)
    func registerWindow(_ window: any WindowProtocol) {
        self.window = window
        if let nsWindow = window as? NSWindow {
            panelWindow = nsWindow
        }
        logger.debug("Panel window registered")
    }

    /// Toggle the translation panel visibility
    func togglePanel() {
        if let window = window {
            if window.isVisible {
                closePanel(window: window)
            } else {
                openPanel(window: window)
            }
        } else {
            // Window not created yet - post notification for SwiftUI to handle
            notificationCenter.post(name: .shouldOpenTranslationPanel, object: nil)
            logger.debug("Posted notification to open panel (window not yet created)")
        }
    }

    /// Close the panel if open
    func closePanel() {
        if let window = window {
            closePanel(window: window)
        }
    }

    /// Reset state (for testing)
    func reset() {
        panelWindow = nil
        window = nil
    }

    // MARK: - Private Methods

    private func openPanel(window: any WindowProtocol) {
        window.makeKeyAndOrderFront(nil)
        activateApp()
        logger.debug("Translation panel opened")
    }

    private func closePanel(window: any WindowProtocol) {
        window.close()
        logger.debug("Translation panel closed")
    }
}
