//
//  TranslationInputView.swift
//  Glimpse
//

import SwiftUI

/// Input text field for the translation panel.
struct TranslationInputView: View {

    // MARK: - Properties

    @Binding var inputText: String
    let onSubmit: () -> Void

    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        TextField("Type here to translate...", text: $inputText, axis: .vertical)
            .textFieldStyle(.plain)
            .font(GlimpseTheme.Typography.body)
            .lineLimit(1...)
            .focused($isInputFocused)
            .onSubmit { onSubmit() }
            .onAppear { isInputFocused = true }
    }
}

#Preview {
    TranslationInputView(
        inputText: .constant("Hello world"),
        onSubmit: {}
    )
    .padding()
}
