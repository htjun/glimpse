//
//  WindowManager.swift
//  Glimpse
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

    /// Mouse event monitor for detecting clicks outside the panel.
    private var mouseMonitor: Any?

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

        // Get captured text before creating view
        let capturedText = TranslationViewModel.shared.consumeCapturedText()

        // Always create fresh hosting view for correct sizing
        let hostingView = NSHostingView(rootView: TranslationPanelView(capturedText: capturedText))

        // Create panel if needed, otherwise update content
        if panel == nil {
            let newPanel = TranslationPanel(contentView: hostingView)
            newPanel.delegate = self
            panel = newPanel
            logger.debug("Panel created")
        } else {
            panel?.contentView = hostingView
        }

        guard let panel else { return }

        // Size and show panel
        centerPanel()
        panel.makeKeyAndOrderFront(nil)
        installMouseMonitor()

        logger.info("Panel opened")
    }

    /// Closes the panel.
    func closePanel() {
        isPanelIntendedOpen = false
        removeMouseMonitor()
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

    private func centerPanel() {
        guard let panel, let screen = NSScreen.main else { return }

        // Force layout recalculation before reading fittingSize
        if let hostingView = panel.contentView as? NSHostingView<TranslationPanelView> {
            hostingView.invalidateIntrinsicContentSize()
            hostingView.layoutSubtreeIfNeeded()
        }

        // Defer sizing to next run loop to ensure SwiftUI layout is complete
        DispatchQueue.main.async { [weak panel, weak screen] in
            guard let panel, let screen else { return }

            let contentSize = panel.contentView?.fittingSize ?? CGSize(width: 720, height: 400)
            panel.setContentSize(contentSize)

            let screenFrame = screen.visibleFrame
            // Position panel above center for better visibility
            let verticalOffset: CGFloat = 100
            let origin = NSPoint(
                x: screenFrame.midX - contentSize.width / 2,
                y: screenFrame.midY - contentSize.height / 2 + verticalOffset
            )
            panel.setFrameOrigin(origin)
        }
    }

    /// Installs a global mouse monitor to detect clicks outside the panel.
    private func installMouseMonitor() {
        removeMouseMonitor()

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let self else { return }

            // Dispatch to main actor for thread safety
            DispatchQueue.main.async {
                guard let panel = self.panel, self.isPanelIntendedOpen else { return }

                let clickLocation = NSEvent.mouseLocation
                if !panel.frame.contains(clickLocation) {
                    self.closePanel()
                }
            }
        }
    }

    /// Removes the mouse event monitor.
    private func removeMouseMonitor() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        isPanelIntendedOpen = false
    }

    func windowDidResignKey(_ notification: Notification) {
        // No-op: We use mouse monitoring instead of focus-based closing.
        // This prevents the panel from closing when system processes
        // (like the Translation API extension) temporarily steal focus.
    }
}
