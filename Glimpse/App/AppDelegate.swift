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

        // If panel is open, just close it
        if WindowManager.shared.isPanelIntendedOpen {
            WindowManager.shared.closePanel()
            logger.debug("Panel closed via toggle")
            return
        }

        // Capture text THEN open panel
        Task {
            let capturedText = await AccessibilityService.shared.captureSelectedText()

            if let text = capturedText, !text.isEmpty {
                TranslationViewModel.shared.capturedText = text
                logger.debug("Captured text: \(text.prefix(50))...")
            }

            WindowManager.shared.openPanel()
        }
    }
}
