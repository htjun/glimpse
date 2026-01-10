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

    private static let accessibilityPromptKey = "AXTrustedCheckOptionPrompt"

    // MARK: - Properties

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Glimpse",
        category: "AppDelegate"
    )

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Glimpse launched")
        checkAccessibilityPermissions()
        registerGlobalHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Glimpse terminating")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Private Methods

    private func checkAccessibilityPermissions() {
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let options: [String: Bool] = [Self.accessibilityPromptKey: !isRunningTests]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if hasPermission {
            logger.info("Accessibility permissions granted")
        } else if isRunningTests {
            logger.info("Accessibility prompt skipped during tests")
        } else {
            logger.warning("Accessibility permissions not granted")
        }
    }

    private func registerGlobalHotkey() {
        KeyboardShortcuts.onKeyUp(for: .toggleTranslationPanel) { [weak self] in
            Task { @MainActor in
                self?.handleHotkeyTriggered()
            }
        }
        logger.info("Global hotkey registered")
    }

    private func handleHotkeyTriggered() {
        if WindowManager.shared.isPanelIntendedOpen {
            WindowManager.shared.closePanel()
            return
        }

        Task {
            let capturedText = await AccessibilityService.shared.captureSelectedText()
            if let text = capturedText, !text.isEmpty {
                TranslationViewModel.shared.capturedText = text
            }
            WindowManager.shared.openPanel()
        }
    }
}
