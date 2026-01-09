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

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Register the panel window reference (called by TranslationPanelView)
    func registerPanelWindow(_ window: NSWindow) {
        panelWindow = window
        logger.debug("Panel window registered")
    }

    /// Toggle the translation panel visibility
    func togglePanel() {
        if let window = panelWindow {
            if window.isVisible {
                closePanel(window: window)
            } else {
                openPanel(window: window)
            }
        } else {
            // Window not created yet - post notification for SwiftUI to handle
            NotificationCenter.default.post(name: .shouldOpenTranslationPanel, object: nil)
            logger.debug("Posted notification to open panel (window not yet created)")
        }
    }

    /// Close the panel if open
    func closePanel() {
        if let window = panelWindow {
            closePanel(window: window)
        }
    }

    // MARK: - Private Methods

    private func openPanel(window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        logger.debug("Translation panel opened")
    }

    private func closePanel(window: NSWindow) {
        window.close()
        logger.debug("Translation panel closed")
    }
}
