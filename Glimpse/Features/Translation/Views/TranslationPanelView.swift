//
//  TranslationPanelView.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
import SwiftUI
import Translation

/// Main translation panel view - floating window activated by hotkey.
struct TranslationPanelView: View {

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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Scrollable content area with max height
            ScrollView {
                VStack(spacing: 16) {
                    // Input text field with loading overlay
                    ZStack(alignment: .leading) {
                        TextField("Enter text to translate...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18))
                            .lineLimit(1...)
                            .focused($isInputFocused)
                            .opacity(TranslationViewModel.shared.isCapturingText && inputText.isEmpty ? 0.3 : 1)
                            .onSubmit {
                                triggerTranslation()
                            }

                        // Show subtle loading indicator while capturing text
                        if TranslationViewModel.shared.isCapturingText && inputText.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Capturing text...")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 14))
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .padding(12)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Translation result or error
                    if !translatedText.isEmpty || isTranslating || translationError != nil {
                        Divider()

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
                }
            }
            .frame(maxHeight: 600)
            .scrollBounceBehavior(.basedOnSize)

            // Action buttons (always visible outside scroll area)
            HStack {
                // Hidden escape button to capture Escape key
                Button("") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .hidden()

                Spacer()

                Button("Translate") {
                    triggerTranslation()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(inputText.isEmpty || isTranslating)
            }
        }
        .padding(20)
        .frame(width: 480, alignment: .top)
        .background(.ultraThinMaterial)
        .background(WindowAccessor())
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            // Reset ALL state for fresh start on each panel open
            inputText = ""
            translatedText = ""
            translationError = nil
            translationConfiguration = nil

            // Populate input with captured text if already available (race condition handling)
            if let capturedText = TranslationViewModel.shared.consumeCapturedText() {
                applyAndTranslate(capturedText)
            }
            isInputFocused = true
        }
        .onChange(of: TranslationViewModel.shared.capturedText) { _, newValue in
            // Handle late-arriving captured text (async text capture)
            if newValue != nil, let text = TranslationViewModel.shared.consumeCapturedText() {
                applyAndTranslate(text)
            }
        }
        .translationTask(translationConfiguration) { @Sendable session in
            // Capture the text before crossing isolation boundary
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
    }

    // MARK: - Private Methods

    /// Applies captured text to input and triggers translation.
    private func applyAndTranslate(_ text: String) {
        inputText = text
        triggerTranslation()
    }

    /// Triggers translation by setting/invalidating the configuration.
    private func triggerTranslation() {
        guard !inputText.isEmpty else { return }

        isTranslating = true
        translationError = nil

        if translationConfiguration == nil {
            // First translation: create configuration
            // source: nil means auto-detect language
            translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "en"),
                target: Locale.Language(identifier: "ko")
            )
        } else {
            // Subsequent translations: invalidate to re-trigger
            translationConfiguration?.invalidate()
        }
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
            WindowManager.shared.registerPanelWindow(window)
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
