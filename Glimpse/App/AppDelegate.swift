//
//  AppDelegate.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
import KeyboardShortcuts
import os.log

/// Application delegate for handling app lifecycle events and global hotkey registration.
@Observable
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Constants

    /// String value of kAXTrustedCheckOptionPrompt constant
    private static let accessibilityPromptKey = "AXTrustedCheckOptionPrompt"

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Glimpse", category: "AppDelegate")

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Glimpse launched successfully")

        // Check and request accessibility permissions
        checkAccessibilityPermissions()

        // Register global hotkey (will be implemented with KeyboardShortcuts)
        registerGlobalHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Glimpse terminating")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in background even when all windows are closed
        false
    }

    // MARK: - Private Methods

    private func checkAccessibilityPermissions() {
        let options: [String: Bool] = [Self.accessibilityPromptKey: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if accessibilityEnabled {
            logger.info("Accessibility permissions granted")
        } else {
            logger.warning("Accessibility permissions not granted - selected text capture will be unavailable")
        }
    }

    private func registerGlobalHotkey() {
        KeyboardShortcuts.onKeyUp(for: .toggleTranslationPanel) { [weak self] in
            Task { @MainActor in
                self?.handleHotkeyTriggered()
            }
        }
        logger.info("Global hotkey registered: toggleTranslationPanel")
    }

    private func handleHotkeyTriggered() {
        logger.debug("Hotkey triggered")

        Task {
            // Capture selected text from the frontmost application before opening the panel
            if let selectedText = await AccessibilityService.shared.getSelectedText() {
                TranslationViewModel.shared.capturedText = selectedText
                logger.debug("Captured text for translation: \(selectedText.prefix(50))...")
            }

            WindowManager.shared.togglePanel()
        }
    }
}
