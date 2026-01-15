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

    // MARK: - Initialization

    /// Optional captured text to translate immediately on open.
    private let initialText: String?

    init(capturedText: String? = nil) {
        self.initialText = capturedText
    }

    // MARK: - Properties

    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var translationError: String?

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
            escapeHandler

            VStack(spacing: 0) {
                // Input section - scrollable, max 200px
                ScrollView {
                    TranslationInputView(
                        inputText: $inputText,
                        onSubmit: performLookup
                    )
                    .padding(.horizontal, GlimpseTheme.Spacing.lg)
                    .padding(.top, GlimpseTheme.Spacing.lg)
                }
                .constrainedScrollSection(maxHeight: 200)

                // Button - fixed height
                translateButtonWithDivider
                    .padding(.bottom, hasResult ? 0 : GlimpseTheme.Spacing.lg)

                // Result section - scrollable, max 500px
                if hasResult || translationError != nil {
                    ScrollView {
                        TranslationResultView(
                            result: translatedText,
                            error: translationError
                        )
                        .padding(.horizontal, GlimpseTheme.Spacing.lg)
                        .padding(.bottom, GlimpseTheme.Spacing.lg)
                    }
                    .constrainedScrollSection(maxHeight: 500)
                }

                // Footer - fixed height
                if hasResult {
                    footerSection
                }
            }
        }
        .panelStyle()
        .onAppear {
            handlePanelOpen(text: initialText)
        }
        .translationTask(translationConfiguration) { @Sendable session in
            let textToTranslate = await MainActor.run { inputText }

            do {
                let response = try await session.translate(textToTranslate)
                await MainActor.run {
                    if response.targetText.isEmpty || response.targetText == textToTranslate {
                        // No meaningful translation found
                        translationError = "No translation found"
                        translatedText = ""
                    } else {
                        translatedText = response.targetText
                        translationError = nil
                    }
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    translationError = "Translation failed"
                    translatedText = ""
                    isTranslating = false
                }
            }
        }
        .onChange(of: languageOne) { retranslateIfNeeded() }
        .onChange(of: languageTwo) { retranslateIfNeeded() }
    }

    // MARK: - Computed Properties

    private var hasResult: Bool {
        !translatedText.isEmpty && !isTranslating
    }

    // MARK: - View Components

    private var escapeHandler: some View {
        Button("") { WindowManager.shared.closePanel() }
            .keyboardShortcut(.escape, modifiers: [])
            .hidden()
            .frame(width: 0, height: 0)
    }

    private var translateButtonWithDivider: some View {
        ZStack {
            if hasResult {
                Divider()
            }

            Button(isTranslating ? "Translating.." : "Translate", action: performLookup)
                .buttonStyle(PrimaryButtonStyle(isLoading: isTranslating))
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(isTranslating || inputText.isEmpty)
        }
    }

    private var footerSection: some View {
        Group {
            TranslationFooterView(
                sourceLanguage: detectedSourceLanguage ?? languageOne,
                targetLanguage: currentConfigTarget ?? languageTwo,
                onCopy: copyTranslation,
                onReplace: replaceOriginalText
            )
            .padding(.horizontal, GlimpseTheme.Spacing.lg)
            .padding(.vertical, GlimpseTheme.Spacing.md)
        }
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

    /// Performs lookup by trying bilingual dictionary first for single words, then falling back to translation.
    private func performLookup() {
        guard !inputText.isEmpty else { return }

        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try bilingual dictionary lookup for single words when one language is English
        if DictionaryService.shared.isSingleWord(trimmed) {
            if let definition = lookupBilingualDefinition(for: trimmed) {
                translatedText = definition
                resultType = .definition
                translationError = nil
                isTranslating = false
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
        let nonEnglishLanguage: SupportedLanguage? = switch (languageOne, languageTwo) {
        case (.english, let other): other
        case (let other, .english): other
        default: nil
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
            detectedSourceLanguage = inputMatchesEnglish ? .english : targetLang
            currentConfigTarget = inputMatchesEnglish ? targetLang : .english
        }

        return definition
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

// MARK: - View Modifiers

extension View {
    /// Applies the standard translation panel styling.
    func panelStyle() -> some View {
        self
            .frame(width: GlimpseTheme.Sizing.panelWidth, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard))
            .background(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                    .fill(GlimpseTheme.Colors.panelBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                    .strokeBorder(GlimpseTheme.Colors.panelBorder, lineWidth: 1)
            )
            .padding(GlimpseTheme.Spacing.xl)
    }

    /// Applies standard scroll section styling with a maximum height constraint.
    func constrainedScrollSection(maxHeight: CGFloat) -> some View {
        self
            .frame(maxHeight: maxHeight)
            .fixedSize(horizontal: false, vertical: true)
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.automatic)
    }
}

#Preview {
    TranslationPanelView()
}
