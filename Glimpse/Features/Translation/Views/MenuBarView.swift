//
//  MenuBarView.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
import SwiftUI

/// Menu bar dropdown view with quick actions and settings access.
struct MenuBarView: View {

    // MARK: - Properties

    let openTranslationPanel: () -> Void

    @Environment(\.openSettings) private var openSettings

    // MARK: - Body

    var body: some View {
        Button("Open Translator") {
            openTranslationPanel()
        }
        .keyboardShortcut("t", modifiers: [.command, .shift])

        Divider()

        Button("Settings...") {
            bringSettingsToFront()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Glimpse") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    // MARK: - Private Methods

    private func bringSettingsToFront() {
        NSApp.activate(ignoringOtherApps: true)

        // Find existing Settings window by title
        if let settingsWindow = NSApp.windows.first(where: { $0.title == "Settings" }) {
            settingsWindow.makeKeyAndOrderFront(nil)
        } else {
            // Window doesn't exist yet, open it
            openSettings()
        }
    }
}

#Preview {
    MenuBarView(openTranslationPanel: {})
}
