//
//  SettingsView.swift
//  Glimpse
//
import KeyboardShortcuts
import SwiftUI

/// Settings view for configuring app preferences.
struct SettingsView: View {

    // MARK: - Properties

    @AppStorage(LanguageSettingsKey.languageOne)
    private var languageOne: SupportedLanguage = .english

    @AppStorage(LanguageSettingsKey.languageTwo)
    private var languageTwo: SupportedLanguage = .korean

    @AppStorage(LocalLLMSettingsKey.translationBackend)
    private var selectedBackend: TranslationBackendType = .apple

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Toggle Translator:", name: .toggleTranslationPanel)
            }

            Section("Languages") {
                languagePairRow
            }

            Section("Translation Engine") {
                TranslationEngineSettingsView(selectedBackend: $selectedBackend)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
    }

    // MARK: - View Components

    private var languagePairRow: some View {
        HStack(spacing: 12) {
            LanguagePicker(selection: $languageOne, excluding: languageTwo)

            Image(systemName: "arrow.left.arrow.right")
                .font(.title3)
                .foregroundStyle(.secondary)

            LanguagePicker(selection: $languageTwo, excluding: languageOne)
        }
    }
}

// MARK: - Language Picker

private struct LanguagePicker: View {
    @Binding var selection: SupportedLanguage
    let excluding: SupportedLanguage

    var body: some View {
        Picker("Language", selection: $selection) {
            ForEach(SupportedLanguage.allCases.filter { $0 != excluding }) { language in
                Text(language.displayName).tag(language)
            }
        }
        .labelsHidden()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView()
}
