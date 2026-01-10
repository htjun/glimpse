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
        // Skip prompting during UI tests to prevent blocking dialogs
        let isRunningUITests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let options: [String: Bool] = [Self.accessibilityPromptKey: !isRunningUITests]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if accessibilityEnabled {
            logger.info("Accessibility permissions granted")
        } else {
            if isRunningUITests {
                logger.info("Accessibility prompt skipped during UI tests")
            } else {
                logger.warning("Accessibility permissions not granted - selected text capture will be unavailable")
            }
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

        // Toggle panel and get session ID (nil means we're closing)
        guard let sessionID = WindowManager.shared.togglePanel() else {
            // User closed the panel - no text capture needed
            logger.debug("Panel closed via toggle")
            return
        }

        // Prepare for new capture (clears previous state, signals loading)
        TranslationViewModel.shared.prepareForNewCapture()

        // Capture text, THEN transfer focus to panel
        Task {
            // Source app still focused here - accessibility APIs work!
            let selectedText = await AccessibilityService.shared.getSelectedText()

            // Only focus if this session is still valid (panel wasn't closed)
            guard WindowManager.shared.focusPanelIfValid(sessionID: sessionID) else {
                logger.debug("Capture completed but panel was closed - discarding")
                return
            }

            if let text = selectedText {
                TranslationViewModel.shared.capturedText = text
                logger.debug("Captured text for translation: \(text.prefix(50))...")
            }
            TranslationViewModel.shared.finishCapture()
        }
    }
}
