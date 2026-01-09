//
//  AccessibilityService.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
import ApplicationServices
import Carbon.HIToolbox
import os.log

/// Service for capturing selected text from other applications via Accessibility APIs.
@MainActor
final class AccessibilityService {

    // MARK: - Singleton

    static let shared = AccessibilityService()

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Glimpse", category: "AccessibilityService")

    /// Timeout for clipboard-based capture in seconds
    private let clipboardTimeout: TimeInterval = 0.5

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Captures the currently selected text from the frontmost application.
    /// Uses a multi-strategy approach: accessibility APIs first, then clipboard fallback.
    /// - Returns: The selected text, or `nil` if no text is selected or capture fails.
    func getSelectedText() async -> String? {
        // Strategy 1: Try accessibility-based capture (fast, non-intrusive)
        if let text = getSelectedTextViaAccessibility() {
            return text
        }

        // Strategy 2: Fallback to clipboard-based capture (works with more apps)
        return await getSelectedTextViaClipboard()
    }

    /// Checks if accessibility permissions are currently granted.
    /// - Returns: `true` if the app has accessibility permissions.
    func hasAccessibilityPermissions() -> Bool {
        AXIsProcessTrusted()
    }

    // MARK: - Private Methods - Accessibility Strategy

    private func getSelectedTextViaAccessibility() -> String? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            logger.debug("No frontmost application found")
            return nil
        }

        let pid = frontmostApp.processIdentifier
        let appName = frontmostApp.localizedName ?? "unknown"
        let appElement = AXUIElementCreateApplication(pid)

        // Enable accessibility for browsers and Electron apps
        enableAccessibilityIfNeeded(for: appElement, appName: appName)

        // Try system-wide element first (works better for some apps)
        if let text = getSelectedTextFromSystemWide() {
            logger.debug("Got text via system-wide element from \(appName)")
            return text
        }

        // Fall back to app-specific element
        if let text = getSelectedTextFromApp(appElement, appName: appName) {
            logger.debug("Got text via app element from \(appName)")
            return text
        }

        logger.debug("Accessibility capture failed for \(appName)")
        return nil
    }

    private func enableAccessibilityIfNeeded(for appElement: AXUIElement, appName: String) {
        // Enable for Chrome/Firefox (AXEnhancedUserInterface)
        let enhancedResult = AXUIElementSetAttributeValue(
            appElement,
            "AXEnhancedUserInterface" as CFString,
            true as CFTypeRef
        )
        if enhancedResult == .success {
            logger.debug("Enabled AXEnhancedUserInterface for \(appName)")
        }

        // Enable for Electron apps (AXManualAccessibility)
        let manualResult = AXUIElementSetAttributeValue(
            appElement,
            "AXManualAccessibility" as CFString,
            true as CFTypeRef
        )
        if manualResult == .success {
            logger.debug("Enabled AXManualAccessibility for \(appName)")
        }
    }

    private func getSelectedTextFromSystemWide() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let element = focusedElement else {
            return nil
        }

        return getSelectedTextFromElement(element as! AXUIElement)
    }

    private func getSelectedTextFromApp(_ appElement: AXUIElement, appName: String) -> String? {
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let element = focusedElement else {
            logger.debug("Could not get focused element from \(appName)")
            return nil
        }

        return getSelectedTextFromElement(element as! AXUIElement)
    }

    private func getSelectedTextFromElement(_ element: AXUIElement) -> String? {
        var selectedText: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        if result == .success, let text = selectedText as? String, !text.isEmpty {
            return text
        }

        return nil
    }

    // MARK: - Private Methods - Clipboard Strategy

    private func getSelectedTextViaClipboard() async -> String? {
        logger.debug("Attempting clipboard-based text capture")

        let pasteboard = NSPasteboard.general

        // Save current clipboard state
        let originalChangeCount = pasteboard.changeCount
        let originalContents = saveClipboardContents(pasteboard)

        // Simulate Cmd+C to copy selected text
        simulateCopy()

        // Wait for clipboard to change (with timeout)
        let capturedText = await waitForClipboardChange(
            pasteboard: pasteboard,
            originalChangeCount: originalChangeCount
        )

        // Restore original clipboard contents
        restoreClipboardContents(pasteboard, contents: originalContents)

        if let text = capturedText, !text.isEmpty {
            logger.debug("Captured text via clipboard: \(text.prefix(50))...")
            return text
        }

        logger.debug("Clipboard-based capture found no text")
        return nil
    }

    private func saveClipboardContents(_ pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType: Data] {
        var contents: [NSPasteboard.PasteboardType: Data] = [:]

        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                contents[type] = data
            }
        }

        return contents
    }

    private func restoreClipboardContents(_ pasteboard: NSPasteboard, contents: [NSPasteboard.PasteboardType: Data]) {
        pasteboard.clearContents()

        for (type, data) in contents {
            pasteboard.setData(data, forType: type)
        }
    }

    private func simulateCopy() {
        // Create Cmd+C key event
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

    private func waitForClipboardChange(pasteboard: NSPasteboard, originalChangeCount: Int) async -> String? {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < clipboardTimeout {
            // Check if clipboard changed
            if pasteboard.changeCount != originalChangeCount {
                return pasteboard.string(forType: .string)
            }

            // Small delay before checking again
            try? await Task.sleep(for: .milliseconds(20))
        }

        return nil
    }
}
