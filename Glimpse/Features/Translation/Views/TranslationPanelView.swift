//
//  TranslationPanelView.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import NaturalLanguage
import os.log
import SwiftUI
import Translation

/// Main translation panel view - floating window activated by hotkey.
struct TranslationPanelView: View {

    // MARK: - Constants

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Glimpse",
        category: "TranslationPanelView"
    )

    // MARK: - Properties

    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var translationError: String?
    @FocusState private var isInputFocused: Bool

    /// The type of the current result (definition or translation).
    @State private var resultType: LookupResultType?

    /// Configuration for the Translation API session.
    /// When set/invalidated, triggers the .translationTask modifier.
    @State private var translationConfiguration: TranslationSession.Configuration?

    /// The target language of the current configuration, used to detect when we need a new config.
    @State private var currentConfigTarget: SupportedLanguage?

    /// The detected source language from the most recent translation.
    @State private var detectedSourceLanguage: SupportedLanguage?

    @AppStorage(LanguageSettingsKey.languageOne)
    private var languageOne: SupportedLanguage = .english

    @AppStorage(LanguageSettingsKey.languageTwo)
    private var languageTwo: SupportedLanguage = .korean

    // MARK: - Body

    var body: some View {
        ZStack {
            // Hidden escape handler
            Button("") { WindowManager.shared.closePanel() }
                .keyboardShortcut(.escape, modifiers: [])
                .hidden()
                .frame(width: 0, height: 0)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        inputField

                        translateButton

                        if !translatedText.isEmpty {
                            resultSection
                        }

                        if let error = translationError {
                            errorSection(error)
                        }
                    }
                    .padding(24)
                }
                .frame(maxHeight: 500)
                .scrollBounceBehavior(.basedOnSize)

                if !translatedText.isEmpty && !isTranslating {
                    Divider()
                        .padding(.horizontal, 24)
                    footerSection
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
            }
            }
        .frame(width: 480, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 247 / 255, green: 247 / 255, blue: 244 / 255))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color(red: 222 / 255, green: 221 / 255, blue: 217 / 255), lineWidth: 1)
        )
        .padding(30)
        .onReceive(NotificationCenter.default.publisher(for: .didCapturePanelText)) { notification in
            let text = notification.userInfo?["text"] as? String
            handlePanelOpen(text: text)
        }
        .translationTask(translationConfiguration) { @Sendable session in
            let textToTranslate = await MainActor.run { inputText }

            do {
                let response = try await session.translate(textToTranslate)
                await MainActor.run {
                    translatedText = response.targetText
                    translationError = nil
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    translationError = "Translation failed: \(error.localizedDescription)"
                    translatedText = ""
                    isTranslating = false
                }
            }
        }
        .onChange(of: languageOne) { retranslateIfNeeded() }
        .onChange(of: languageTwo) { retranslateIfNeeded() }
    }

    // MARK: - View Components

    private var inputField: some View {
        TextField("Type here to translate...", text: $inputText, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: 18))
            .lineLimit(1...)
            .focused($isInputFocused)
            .onSubmit { performLookup() }
    }

    @ViewBuilder
    private var translateButton: some View {
        if isTranslating {
            Button(action: {}) {
                Text("Translating..")
            }
            .buttonStyle(LoadingButtonStyle())
            .disabled(true)
        } else {
            Button(action: { performLookup() }) {
                Text("Translate")
            }
            .buttonStyle(PrimaryButtonStyle())
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(inputText.isEmpty)
        }
    }

    private var resultSection: some View {
        Text(translatedText)
            .font(.system(size: 18))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }

    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(error)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var footerSection: some View {
        TranslationFooterView(
            sourceLanguage: detectedSourceLanguage ?? languageOne,
            targetLanguage: currentConfigTarget ?? languageTwo,
            onCopy: copyTranslation,
            onReplace: replaceOriginalText
        )
    }

    // MARK: - Private Methods

    /// Handles panel open event, optionally with captured text.
    private func handlePanelOpen(text: String?) {
        Self.logger.info("Panel opened, captured text: \(text != nil ? "yes" : "no")")
        resetState()
        if let text {
            inputText = text
            performLookup()
        }
        isInputFocused = true
    }

    /// Resets all state for a fresh panel open.
    private func resetState() {
        inputText = ""
        translatedText = ""
        translationError = nil
        isTranslating = false
        resultType = nil
        detectedSourceLanguage = nil
    }

    /// Performs lookup by trying dictionary first for single words, then falling back to translation.
    private func performLookup() {
        guard !inputText.isEmpty else { return }

        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try dictionary lookup for single words
        if DictionaryService.shared.isSingleWord(trimmed),
           let definition = DictionaryService.shared.lookupDefinition(for: trimmed) {
            translatedText = definition
            resultType = .definition
            translationError = nil
            isTranslating = false
            Self.logger.info("Dictionary lookup succeeded for: \(trimmed.prefix(20))")
            return
        }

        // Fall back to translation
        triggerTranslation()
    }

    /// Triggers translation by setting/invalidating the configuration.
    private func triggerTranslation() {
        guard !inputText.isEmpty else { return }

        isTranslating = true
        translationError = nil
        resultType = .translation

        let targetLanguage = determineTargetLanguage(for: inputText)

        // If we have a config with the same target, just invalidate to re-run
        if translationConfiguration != nil && currentConfigTarget == targetLanguage {
            translationConfiguration?.invalidate()
        } else {
            // Need a new config for different target language
            currentConfigTarget = targetLanguage
            translationConfiguration = TranslationSession.Configuration(
                source: nil,
                target: targetLanguage.localeLanguage
            )
        }
    }

    /// Detects the dominant language of the input text.
    private func detectLanguage(_ text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage
    }

    /// Determines the target language based on detected input language.
    /// If input matches languageOne, translates to languageTwo, and vice versa.
    private func determineTargetLanguage(for text: String) -> SupportedLanguage {
        guard let detected = detectLanguage(text) else {
            Self.logger.info("Language detection failed, defaulting to \(self.languageTwo.displayName)")
            detectedSourceLanguage = languageOne
            return languageTwo
        }

        Self.logger.info("Detected language: \(detected.rawValue)")

        let inputMatchesLanguageOne = detected.rawValue == languageOne.rawValue
        detectedSourceLanguage = inputMatchesLanguageOne ? languageOne : languageTwo
        return inputMatchesLanguageOne ? languageTwo : languageOne
    }

    /// Re-triggers translation if there's existing input text.
    private func retranslateIfNeeded() {
        guard !inputText.isEmpty, translationConfiguration != nil else { return }
        triggerTranslation()
    }

    /// Copies the translated text to the clipboard.
    private func copyTranslation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
        Self.logger.info("Translation copied to clipboard")
    }

    /// Replaces the original selected text with the translation.
    private func replaceOriginalText() {
        // TODO: Implement replace functionality using accessibility APIs
        Self.logger.info("Replace requested (not yet implemented)")
    }

}

#Preview {
    TranslationPanelView()
}
