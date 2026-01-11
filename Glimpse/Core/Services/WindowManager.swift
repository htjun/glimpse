//
//  WindowManager.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
import os.log
import SwiftUI

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

    /// The translation panel instance.
    private(set) var panel: TranslationPanel?

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

        // Create panel lazily
        if panel == nil {
            createPanel()
        }

        guard let panel else { return }

        // Post notification before showing (includes captured text if available)
        postPanelOpenNotification()

        // Center and show panel
        centerPanel()
        panel.makeKeyAndOrderFront(nil)

        logger.info("Panel opened")
    }

    /// Closes the panel.
    func closePanel() {
        isPanelIntendedOpen = false
        panel?.orderOut(nil)
        logger.debug("Panel closed")
    }

    /// Reset state (for testing).
    func reset() {
        panel?.close()
        panel = nil
        isPanelIntendedOpen = false
    }

    // MARK: - Private Methods

    private func createPanel() {
        let hostingView = NSHostingView(rootView: TranslationPanelView())
        hostingView.setFrameSize(hostingView.fittingSize)

        let newPanel = TranslationPanel(contentView: hostingView)
        newPanel.delegate = self
        panel = newPanel

        logger.debug("Panel created")
    }

    private func centerPanel() {
        guard let panel, let screen = NSScreen.main else { return }

        let contentSize = panel.contentView?.fittingSize ?? CGSize(width: 480, height: 200)
        panel.setContentSize(contentSize)

        let screenFrame = screen.visibleFrame
        let origin = NSPoint(
            x: screenFrame.midX - contentSize.width / 2,
            y: screenFrame.midY - contentSize.height / 2 + 100
        )
        panel.setFrameOrigin(origin)
    }

    private func postPanelOpenNotification() {
        let capturedText = TranslationViewModel.shared.consumeCapturedText()
        var userInfo: [String: Any] = [:]
        if let text = capturedText {
            userInfo["text"] = text
        }
        notificationCenter.post(
            name: .didCapturePanelText,
            object: nil,
            userInfo: userInfo.isEmpty ? nil : userInfo
        )
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        isPanelIntendedOpen = false
    }
}
