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

    /// Wait times for clipboard capture with increasing delays for retry
    private let clipboardWaitTimes: [Duration] = [
        .milliseconds(100),
        .milliseconds(150),
        .milliseconds(200)
    ]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Captures the currently selected text by simulating Cmd+C.
    /// Preserves the user's original clipboard contents.
    /// Uses retry with increasing delays for reliability on slower systems.
    /// - Returns: The selected text, or `nil` if no text is selected or capture fails.
    func captureSelectedText() async -> String? {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let savedItems = saveClipboardContents()
        let originalChangeCount = pasteboard.changeCount

        // Simulate Cmd+C to copy selected text
        simulateCopy()

        // Try waiting with increasing delays
        var capturedText: String?
        for (index, waitTime) in clipboardWaitTimes.enumerated() {
            try? await Task.sleep(for: waitTime)

            if pasteboard.changeCount != originalChangeCount {
                capturedText = pasteboard.string(forType: .string)
                if capturedText != nil && !capturedText!.isEmpty {
                    logger.debug("Captured text on attempt \(index + 1)")
                    break
                }
            }
        }

        // Restore original clipboard contents
        restoreClipboardContents(savedItems)

        if let text = capturedText, !text.isEmpty {
            logger.debug("Captured text: \(text.prefix(50))...")
            return text
        }

        logger.debug("No text captured after \(clipboardWaitTimes.count) attempts")
        return nil
    }

    /// Checks if accessibility permissions are currently granted.
    /// - Returns: `true` if the app has accessibility permissions.
    func hasAccessibilityPermissions() -> Bool {
        AXIsProcessTrusted()
    }

    // MARK: - Clipboard Save/Restore

    private struct ClipboardItem {
        let types: [NSPasteboard.PasteboardType]
        let dataByType: [NSPasteboard.PasteboardType: Data]
    }

    private func saveClipboardContents() -> [ClipboardItem] {
        let pasteboard = NSPasteboard.general
        var items: [ClipboardItem] = []

        for item in pasteboard.pasteboardItems ?? [] {
            var dataByType: [NSPasteboard.PasteboardType: Data] = [:]
            let types = item.types

            for type in types {
                if let data = item.data(forType: type) {
                    dataByType[type] = data
                }
            }

            if !dataByType.isEmpty {
                items.append(ClipboardItem(types: types, dataByType: dataByType))
            }
        }

        return items
    }

    private func restoreClipboardContents(_ items: [ClipboardItem]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        for item in items {
            let pasteboardItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.dataByType[type] {
                    pasteboardItem.setData(data, forType: type)
                }
            }
            pasteboard.writeObjects([pasteboardItem])
        }
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
