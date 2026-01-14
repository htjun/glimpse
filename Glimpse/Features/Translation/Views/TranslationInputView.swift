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
    @State private var selection: TextSelection?

    // MARK: - Body

    var body: some View {
        TextField("Type here to translate...", text: $inputText, selection: $selection, axis: .vertical)
            .textFieldStyle(.plain)
            .font(GlimpseTheme.Typography.body)
            .lineLimit(1...)
            .focused($isInputFocused)
            .onSubmit { onSubmit() }
            .onAppear {
                isInputFocused = true
                DispatchQueue.main.async {
                    selection = TextSelection(insertionPoint: inputText.endIndex)
                }
            }
    }
}

#Preview {
    TranslationInputView(
        inputText: .constant("Hello world"),
        onSubmit: {}
    )
    .padding()
}
