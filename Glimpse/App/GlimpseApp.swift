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
    @Environment(\.openWindow) private var openWindow

    // MARK: - Body

    var body: some Scene {
        // Menu bar icon and dropdown menu
        MenuBarExtra("Glimpse", systemImage: "character.bubble") {
            MenuBarView(openTranslationPanel: { openWindow(id: "translation-panel") })
        }
        .menuBarExtraStyle(.menu)

        // Floating translation panel window
        Window("Glimpse", id: "translation-panel") {
            TranslationPanelView()
        }
        .windowLevel(.floating)
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
