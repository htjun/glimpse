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
        MenuBarExtra("Glimpse", systemImage: "character.bubble") {
            MenuBarView(openTranslationPanel: { openWindow(id: "translation-panel") })
        }
        .menuBarExtraStyle(.menu)

        Window("Glimpse", id: "translation-panel") {
            TranslationPanelView()
        }
        .windowLevel(.floating)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Hidden helper window that bridges notifications to SwiftUI openWindow action.
        // Required because hotkey handler cannot access @Environment(\.openWindow).
        WindowGroup(id: "helper") {
            OpenPanelListener(openWindow: openWindow)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.presented)

        Settings {
            SettingsView()
        }
    }
}

// MARK: - Open Panel Listener

/// Bridges notification-based panel open requests to SwiftUI's openWindow action.
private struct OpenPanelListener: View {
    let openWindow: OpenWindowAction

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onReceive(NotificationCenter.default.publisher(for: .shouldOpenTranslationPanel)) { _ in
                openWindow(id: "translation-panel")
            }
            .task {
                await hideHelperWindow()
            }
    }

    private func hideHelperWindow() async {
        try? await Task.sleep(for: .milliseconds(100))
        await MainActor.run {
            guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue.contains("helper") == true }) else {
                return
            }
            window.setIsVisible(false)
            window.orderOut(nil)
        }
    }
}
