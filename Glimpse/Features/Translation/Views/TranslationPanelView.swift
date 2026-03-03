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

// MARK: - Constants

private enum TranslationError {
    static let noTranslationFound = "No translation found"
    static let translationFailed = "Translation failed"
}

// MARK: - Translation State

/// Consolidated state for the translation panel.
private struct TranslationState {
    var inputText: String = ""
    var translatedText: String = ""
    var isTranslating: Bool = false
    var translationError: String?
    var detectedSourceLanguage: SupportedLanguage?
    var currentConfigTarget: SupportedLanguage?
    var isAutoDetect: Bool = true

    /// Resets all state for a fresh panel open.
    mutating func reset() {
        inputText = ""
        translatedText = ""
        isTranslating = false
        translationError = nil
        detectedSourceLanguage = nil
        currentConfigTarget = nil
        isAutoDetect = true
    }
}

/// Main translation panel view - floating window activated by hotkey.
/// Two-column layout matching Apple Translate app design.
struct TranslationPanelView: View {

    // MARK: - Constants

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Glimpse",
        category: "TranslationPanelView"
    )

    // MARK: - Initialization

    /// Optional captured text to translate immediately on open.
    private let initialText: String?

    init(capturedText: String? = nil) {
        self.initialText = capturedText
    }

    // MARK: - Properties

    @State private var state = TranslationState()

    /// Configuration for the Apple Translation API session.
    /// Only used when Apple Translation backend is selected.
    @State private var translationConfiguration: TranslationSession.Configuration?

    /// Task for streaming LocalLLM translation (for cancellation support).
    @State private var streamingTask: Task<Void, Never>?

    @AppStorage(LanguageSettingsKey.languageOne)
    private var languageOne: SupportedLanguage = .english

    @AppStorage(LanguageSettingsKey.languageTwo)
    private var languageTwo: SupportedLanguage = .korean

    @AppStorage(LocalLLMSettingsKey.translationBackend)
    private var selectedBackend: TranslationBackendType = .apple

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            SourceColumnView(
                inputText: $state.inputText,
                sourceLanguage: $languageOne,
                detectedLanguage: state.detectedSourceLanguage,
                isAutoDetect: $state.isAutoDetect,
                onSubmit: performLookup
            )

            TargetColumnView(
                translatedText: state.translatedText,
                isTranslating: state.isTranslating,
                error: state.translationError,
                targetLanguage: $languageTwo,
                hasTranslation: hasResult,
                onCopy: copyTranslation
            )
        }
        .frame(minHeight: GlimpseTheme.Sizing.contentHeight)
        .containerStyle()
        .overlay { keyboardHandlers }
        .onAppear {
            handlePanelOpen(text: initialText)
        }
        .translationTask(translationConfiguration) { @Sendable session in
            // Only used when Apple Translation backend is selected
            let textToTranslate = await MainActor.run { state.inputText }

            do {
                let response = try await session.translate(textToTranslate)
                await MainActor.run {
                    if response.targetText.isEmpty || response.targetText == textToTranslate {
                        state.translationError = TranslationError.noTranslationFound
                        state.translatedText = ""
                    } else {
                        state.translatedText = response.targetText
                        state.translationError = nil
                    }
                    state.isTranslating = false
                }
            } catch {
                await MainActor.run {
                    state.translationError = TranslationError.translationFailed
                    state.translatedText = ""
                    state.isTranslating = false
                }
            }
        }
        .onChange(of: languageOne) { retranslateIfNeeded() }
        .onChange(of: languageTwo) { retranslateIfNeeded() }
    }

    // MARK: - Computed Properties

    private var hasResult: Bool {
        !state.translatedText.isEmpty && !state.isTranslating
    }

    // MARK: - View Components

    /// Hidden buttons for keyboard shortcuts
    private var keyboardHandlers: some View {
        Group {
            // Escape to close
            Button("") { WindowManager.shared.closePanel() }
                .keyboardShortcut(.escape, modifiers: [])

            // Command+Return to copy translation
            Button("") { copyTranslation() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!hasResult)
        }
        .hidden()
        .frame(width: 0, height: 0)
    }

    // MARK: - Private Methods

    /// Handles panel open event, optionally with captured text.
    private func handlePanelOpen(text: String?) {
        Self.logger.info("Panel opened, captured text: \(text != nil ? "yes" : "no")")
        // Cancel any existing streaming task
        streamingTask?.cancel()
        streamingTask = nil
        state.reset()
        translationConfiguration = nil
        if let text {
            state.inputText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            performLookup()
        }
    }

    /// Performs lookup by trying bilingual dictionary first for single words, then falling back to translation.
    private func performLookup() {
        guard !state.inputText.isEmpty else { return }

        let trimmed = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try bilingual dictionary lookup for single words when one language is English
        if DictionaryService.shared.isSingleWord(trimmed) {
            if let definition = lookupBilingualDefinition(for: trimmed) {
                state.translatedText = definition
                state.translationError = nil
                state.isTranslating = false
                Self.logger.info("Bilingual dictionary lookup succeeded for: \(trimmed.prefix(20))")
                return
            }
        }

        // Fall back to translation
        triggerTranslation()
    }

    /// Attempts bilingual dictionary lookup when one of the language pair is English.
    /// Returns the definition if found, or nil to fall back to translation.
    private func lookupBilingualDefinition(for word: String) -> String? {
        // Bilingual dictionaries are always paired with English
        let nonEnglishLanguage: SupportedLanguage?
        if languageOne == .english {
            nonEnglishLanguage = languageTwo
        } else if languageTwo == .english {
            nonEnglishLanguage = languageOne
        } else {
            nonEnglishLanguage = nil
        }

        guard let targetLang = nonEnglishLanguage,
              let pattern = targetLang.bilingualDictionaryPattern else {
            Self.logger.debug("No bilingual dictionary for language pair")
            return nil
        }

        guard let definition = DictionaryService.shared.lookupBilingualDefinition(
            for: word,
            languagePattern: pattern
        ) else {
            return nil
        }

        // Update detected source language based on input language
        if let detected = detectLanguage(word) {
            let inputMatchesEnglish = detected.rawValue == SupportedLanguage.english.rawValue
            state.detectedSourceLanguage = inputMatchesEnglish ? .english : targetLang
            state.currentConfigTarget = inputMatchesEnglish ? targetLang : .english
        }

        return definition
    }

    /// Triggers translation using the configured backend.
    private func triggerTranslation() {
        guard !state.inputText.isEmpty else { return }

        state.isTranslating = true
        state.translationError = nil

        let targetLanguage = determineTargetLanguage(for: state.inputText)
        state.currentConfigTarget = targetLanguage

        switch selectedBackend {
        case .apple:
            // Use Apple Translation API via .translationTask modifier
            triggerAppleTranslation(to: targetLanguage)
        case .localLLM:
            // Use Local LLM via TranslationCoordinator
            triggerLocalLLMTranslation(to: targetLanguage)
        }
    }

    /// Triggers Apple Translation API by setting/invalidating the configuration.
    private func triggerAppleTranslation(to targetLanguage: SupportedLanguage) {
        // If we have a config with the same target, just invalidate to re-run
        if translationConfiguration != nil && state.currentConfigTarget == targetLanguage {
            translationConfiguration?.invalidate()
        } else {
            // Need a new config for different target language
            translationConfiguration = TranslationSession.Configuration(
                source: nil,
                target: targetLanguage.localeLanguage
            )
        }
    }

    /// Triggers Local LLM translation with streaming output.
    private func triggerLocalLLMTranslation(to targetLanguage: SupportedLanguage) {
        // Cancel any existing streaming task
        streamingTask?.cancel()

        let sourceLanguage = state.isAutoDetect ? nil : languageOne
        let inputText = state.inputText

        streamingTask = Task {
            #if canImport(MLXLLM)
            do {
                let result = try await LocalLLMTranslationBackend.shared.translateStreaming(
                    text: inputText,
                    from: sourceLanguage,
                    to: targetLanguage
                )

                // Update detected language immediately
                if let detected = result.detectedSourceLanguage {
                    state.detectedSourceLanguage = detected
                }

                // Clear and stream incrementally
                state.translatedText = ""
                state.translationError = nil

                for await text in result.textStream {
                    // Check for cancellation
                    if Task.isCancelled { break }

                    // Update UI with streamed text
                    state.translatedText = text
                }

                // Validate final result
                if state.translatedText.isEmpty || state.translatedText == inputText {
                    state.translationError = TranslationError.noTranslationFound
                    state.translatedText = ""
                }
            } catch {
                if !Task.isCancelled {
                    state.translationError = error.localizedDescription
                    state.translatedText = ""
                    Self.logger.error("Local LLM translation failed: \(error.localizedDescription)")
                }
            }

            if !Task.isCancelled {
                state.isTranslating = false
            }
            #else
            // Fallback for when MLXLLM is not available
            state.translationError = "Local LLM not available"
            state.isTranslating = false
            #endif
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
            state.detectedSourceLanguage = languageOne
            return languageTwo
        }

        Self.logger.info("Detected language: \(detected.rawValue)")

        let inputMatchesLanguageOne = detected.rawValue == languageOne.rawValue
        state.detectedSourceLanguage = inputMatchesLanguageOne ? languageOne : languageTwo
        return inputMatchesLanguageOne ? languageTwo : languageOne
    }

    /// Re-triggers translation if there's existing input text.
    private func retranslateIfNeeded() {
        guard !state.inputText.isEmpty else { return }
        triggerTranslation()
    }

    /// Copies the translated text to the clipboard.
    private func copyTranslation() {
        guard hasResult else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(state.translatedText, forType: .string)
        Self.logger.info("Translation copied to clipboard")
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies the new container styling for the translation panel.
    func containerStyle() -> some View {
        let cornerRadius = GlimpseTheme.Radii.container
        return self
            .padding(GlimpseTheme.Sizing.innerPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GlimpseTheme.Colors.containerBackground)
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.08), radius: 32, x: 0, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(GlimpseTheme.Colors.containerBorder, lineWidth: 1)
            )
            .padding(GlimpseTheme.Sizing.outerPadding)
    }
}

#Preview {
    TranslationPanelView()
}
