//
//  AccessibilityService.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
import Carbon.HIToolbox
import os.log

/// Service for capturing selected text from other applications via clipboard simulation.
@MainActor
final class AccessibilityService {

    // MARK: - Singleton

    static let shared = AccessibilityService()

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Glimpse", category: "AccessibilityService")

    /// Wait time for clipboard to update after simulating Cmd+C
    private let clipboardWaitTime: Duration = .milliseconds(100)

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Captures the currently selected text by simulating Cmd+C.
    /// - Returns: The selected text, or `nil` if no text is selected or capture fails.
    func captureSelectedText() async -> String? {
        let pasteboard = NSPasteboard.general
        let originalChangeCount = pasteboard.changeCount

        // Simulate Cmd+C to copy selected text
        simulateCopy()

        // Wait for clipboard to update
        try? await Task.sleep(for: clipboardWaitTime)

        // Check if clipboard changed
        if pasteboard.changeCount != originalChangeCount {
            if let text = pasteboard.string(forType: .string), !text.isEmpty {
                logger.debug("Captured text: \(text.prefix(50))...")
                return text
            }
        }

        logger.debug("No text captured (clipboard unchanged or empty)")
        return nil
    }

    /// Checks if accessibility permissions are currently granted.
    /// - Returns: `true` if the app has accessibility permissions.
    func hasAccessibilityPermissions() -> Bool {
        AXIsProcessTrusted()
    }

    // MARK: - Private Methods

    private func simulateCopy() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down: C with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }

        // Key up: C with Command modifier
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
