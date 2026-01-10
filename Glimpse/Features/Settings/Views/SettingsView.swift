//
//  SettingsView.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 1/11/2026.
//

import SwiftUI
import KeyboardShortcuts

/// Settings view for configuring app preferences.
struct SettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle Translator:", name: .toggleTranslationPanel)
        }
        .formStyle(.grouped)
        .frame(width: 300)
    }
}

#Preview {
    SettingsView()
}
