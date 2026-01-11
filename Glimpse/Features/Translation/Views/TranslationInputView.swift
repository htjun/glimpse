//
//  TranslationInputView.swift
//  Glimpse
//

import SwiftUI

/// Input field and translate button for the translation panel.
struct TranslationInputView: View {

    // MARK: - Properties

    @Binding var inputText: String
    let isTranslating: Bool
    let onTranslate: () -> Void

    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: GlimpseTheme.Spacing.lg) {
            TextField("Type here to translate...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(GlimpseTheme.Typography.body)
                .lineLimit(1...)
                .focused($isInputFocused)
                .onSubmit { onTranslate() }

            translateButton
        }
        .onAppear { isInputFocused = true }
    }

    // MARK: - View Components

    private var translateButton: some View {
        Button(action: isTranslating ? {} : onTranslate) {
            Text(isTranslating ? "Translating.." : "Translate")
        }
        .buttonStyle(PrimaryButtonStyle(isLoading: isTranslating))
        .keyboardShortcut(.return, modifiers: .command)
        .disabled(isTranslating || inputText.isEmpty)
    }
}

#Preview {
    TranslationInputView(
        inputText: .constant("Hello world"),
        isTranslating: false,
        onTranslate: {}
    )
    .padding()
}
