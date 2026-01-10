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

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Glimpse",
        category: "WindowManager"
    )

    /// Window reference using protocol for testability.
    /// When registered as NSWindow, also stored in panelWindow for delegate access.
    private(set) var window: (any WindowProtocol)?

    /// Concrete NSWindow reference for delegate functionality.
    private(set) var panelWindow: NSWindow?

    /// Tracks the intended panel state.
    private(set) var isPanelIntendedOpen: Bool = false

    /// Notification center (injectable for testing).
    var notificationCenter: NotificationCenter = .default

    /// Application activator (injectable for testing).
    var activateApp: () -> Void = {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    /// Internal initializer for testing.
    init(
        notificationCenter: NotificationCenter = .default,
        activateApp: @escaping () -> Void = { NSApplication.shared.activate(ignoringOtherApps: true) }
    ) {
        super.init()
        self.notificationCenter = notificationCenter
        self.activateApp = activateApp
    }

    // MARK: - Public Methods

    /// Register the panel window reference.
    func registerWindow(_ window: any WindowProtocol) {
        self.window = window
        if let nsWindow = window as? NSWindow {
            panelWindow = nsWindow
            nsWindow.delegate = self
        }
        logger.debug("Panel window registered")
    }

    /// Toggle the translation panel visibility.
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

        if let window {
            window.makeKeyAndOrderFront(nil)
            postCapturedTextNotificationIfNeeded()
        } else {
            notificationCenter.post(name: .shouldOpenTranslationPanel, object: nil)
        }
        logger.info("Panel opened, window exists: \(self.window != nil)")
    }

    /// Closes the panel.
    func closePanel() {
        isPanelIntendedOpen = false
        window?.close()
        logger.debug("Panel closed")
    }

    /// Reset state (for testing).
    func reset() {
        window = nil
        panelWindow = nil
        isPanelIntendedOpen = false
    }

    // MARK: - Private Methods

    private func postCapturedTextNotificationIfNeeded() {
        guard let text = TranslationViewModel.shared.consumeCapturedText() else { return }
        notificationCenter.post(
            name: .didCapturePanelText,
            object: nil,
            userInfo: ["text": text]
        )
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        isPanelIntendedOpen = false
    }
}
