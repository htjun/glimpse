//
//  MenuBarView.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import SwiftUI

/// Menu bar dropdown view with quick actions and settings access.
struct MenuBarView: View {

    // MARK: - Properties

    let openTranslationPanel: () -> Void

    // MARK: - Body

    var body: some View {
        Button("Open Translator") {
            openTranslationPanel()
        }
        .keyboardShortcut("t", modifiers: [.command, .shift])

        Divider()

        SettingsLink(label: { Text("Settings...") })
            .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Glimpse") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

#Preview {
    MenuBarView(openTranslationPanel: {})
}
