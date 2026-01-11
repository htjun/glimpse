//
//  TranslationPanelView.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
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
    @Environment(\.dismiss) private var dismiss

    /// Configuration for the Translation API session.
    /// When set/invalidated, triggers the .translationTask modifier.
    @State private var translationConfiguration: TranslationSession.Configuration?

    /// The target language of the current configuration, used to detect when we need a new config.
    @State private var currentConfigTarget: SupportedLanguage?

    @AppStorage(LanguageSettingsKey.languageOne)
    private var languageOne: SupportedLanguage = .english

    @AppStorage(LanguageSettingsKey.languageTwo)
    private var languageTwo: SupportedLanguage = .korean

    /// Whether to show the result section (translation, loading, or error).
    private var showsResultSection: Bool {
        !translatedText.isEmpty || isTranslating || translationError != nil
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 16) {
                    inputField
                    if showsResultSection {
                        Divider()
                        resultSection
                    }
                }
            }
            .frame(maxHeight: 600)
            .scrollBounceBehavior(.basedOnSize)

            buttonBar
        }
        .padding(20)
        .frame(width: 480, alignment: .top)
        .background(.ultraThinMaterial)
        .background(WindowAccessor())
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            handlePanelOpen(text: TranslationViewModel.shared.consumeCapturedText())
        }
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
        TextField("Enter text to translate...", text: $inputText, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: 18))
            .lineLimit(1...)
            .focused($isInputFocused)
            .onSubmit { triggerTranslation() }
            .padding(12)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var resultSection: some View {
        if isTranslating {
            ProgressView()
                .scaleEffect(0.8)
                .frame(maxWidth: .infinity, minHeight: 40)
        } else if let error = translationError {
            Text(error)
                .font(.system(size: 14))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        } else {
            Text(translatedText)
                .font(.system(size: 18))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(12)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var buttonBar: some View {
        HStack {
            Button("") { dismiss() }
                .keyboardShortcut(.escape, modifiers: [])
                .hidden()

            Spacer()

            Button("Translate") { triggerTranslation() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(inputText.isEmpty || isTranslating)
        }
    }

    // MARK: - Private Methods

    /// Handles panel open event, optionally with captured text.
    private func handlePanelOpen(text: String?) {
        Self.logger.info("Panel opened, captured text: \(text != nil ? "yes" : "no")")
        resetState()
        if let text {
            inputText = text
            triggerTranslation()
        }
        isInputFocused = true
    }

    /// Resets all state for a fresh panel open.
    private func resetState() {
        inputText = ""
        translatedText = ""
        translationError = nil
        isTranslating = false
    }

    /// Triggers translation by setting/invalidating the configuration.
    private func triggerTranslation() {
        guard !inputText.isEmpty else { return }

        isTranslating = true
        translationError = nil

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
            return languageTwo
        }

        Self.logger.info("Detected language: \(detected.rawValue)")

        if detected.rawValue == languageOne.rawValue {
            return languageTwo
        }
        return languageOne
    }

    /// Re-triggers translation if there's existing input text.
    private func retranslateIfNeeded() {
        guard !inputText.isEmpty, translationConfiguration != nil else { return }
        triggerTranslation()
    }

}

#Preview {
    TranslationPanelView()
}

// MARK: - Window Accessor

/// Custom NSView that captures window reference when added to hierarchy.
private class WindowCaptureView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            WindowManager.shared.registerWindow(window)
        }
    }
}

/// Captures the NSWindow reference and registers it with WindowManager.
private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowCaptureView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
