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
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Invisible helper window group - auto-created at app launch
        // Listens for notifications and triggers openWindow action
        WindowGroup(id: "helper") {
            OpenPanelListener(openWindow: openWindow)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.presented)
    }
}

// MARK: - Open Panel Listener

/// Listens for panel open requests and triggers the SwiftUI openWindow action.
/// This view is placed in a persistent helper window that exists throughout app lifecycle.
private struct OpenPanelListener: View {
    let openWindow: OpenWindowAction

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onReceive(NotificationCenter.default.publisher(for: .shouldOpenTranslationPanel)) { _ in
                openWindow(id: "translation-panel")
            }
            .task {
                // Hide the helper window after it's created
                try? await Task.sleep(for: .milliseconds(100))
                await MainActor.run {
                    if let window = NSApp.windows.first(where: {
                        $0.identifier?.rawValue.contains("helper") == true
                    }) {
                        window.setIsVisible(false)
                        window.orderOut(nil)
                    }
                }
            }
    }
}
