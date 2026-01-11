//
//  GlimpseApp.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import SwiftUI

@main
struct GlimpseApp: App {

    // MARK: - Properties

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        MenuBarExtra("Glimpse", systemImage: "character.bubble") {
            MenuBarView(openTranslationPanel: { WindowManager.shared.openPanel() })
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
