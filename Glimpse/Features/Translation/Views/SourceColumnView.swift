//
//  SourceColumnView.swift
//  Glimpse
//

import SwiftUI

/// Left column with source text input.
struct SourceColumnView: View {

    // MARK: - Properties

    @Binding var inputText: String
    let onSubmit: () -> Void

    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            GlimpseTheme.Colors.sourceColumnBackground

            // Placeholder
            if inputText.isEmpty {
                Text("Enter text...")
                    .font(GlimpseTheme.Typography.body)
                    .foregroundStyle(GlimpseTheme.Colors.placeholderText)
                    .padding(GlimpseTheme.Spacing.lg)
                    .allowsHitTesting(false)
            }

            // Text editor
            TextEditor(text: $inputText)
                .font(GlimpseTheme.Typography.body)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .fixedSize(horizontal: false, vertical: true)
                .padding(GlimpseTheme.Spacing.md)
                .focused($isInputFocused)
                .accessibilityLabel("Text to translate")
                .accessibilityHint("Enter text you want to translate")
        }
        .frame(minWidth: GlimpseTheme.Sizing.columnMinWidth, minHeight: GlimpseTheme.Sizing.textAreaMinHeight)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: GlimpseTheme.Radii.standard,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        )
        .onAppear {
            isInputFocused = true
        }
        .onSubmit {
            onSubmit()
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        SourceColumnView(
            inputText: .constant(""),
            onSubmit: {}
        )

        SourceColumnView(
            inputText: .constant("Hello, how are you today?"),
            onSubmit: {}
        )
    }
    .frame(height: 300)
}
