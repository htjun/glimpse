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

    // MARK: - Properties

    @AppStorage(LanguageSettingsKey.languageOne)
    private var languageOne: SupportedLanguage = .english

    @AppStorage(LanguageSettingsKey.languageTwo)
    private var languageTwo: SupportedLanguage = .korean

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Toggle Translator:", name: .toggleTranslationPanel)
            }

            Section("Languages") {
                languagePairRow
            }
        }
        .formStyle(.grouped)
        .frame(width: 350)
    }

    // MARK: - View Components

    private var languagePairRow: some View {
        HStack(spacing: 12) {
            Picker("Language 1", selection: $languageOne) {
                ForEach(availableLanguages(excluding: languageTwo)) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Image(systemName: "arrow.left.arrow.right")
                .font(.title3)
                .foregroundStyle(.secondary)

            Picker("Language 2", selection: $languageTwo) {
                ForEach(availableLanguages(excluding: languageOne)) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Private Methods

    /// Returns all languages except the excluded one.
    private func availableLanguages(excluding: SupportedLanguage) -> [SupportedLanguage] {
        SupportedLanguage.allCases.filter { $0 != excluding }
    }
}

#Preview {
    SettingsView()
}
