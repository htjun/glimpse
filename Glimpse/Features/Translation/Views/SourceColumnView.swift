//
//  SourceColumnView.swift
//  Glimpse
//

import SwiftUI

/// Left column with source text input.
/// Contains embedded language selector and settings button.
struct SourceColumnView: View {

    // MARK: - Properties

    @Binding var inputText: String
    @Binding var sourceLanguage: SupportedLanguage
    let detectedLanguage: SupportedLanguage?
    @Binding var isAutoDetect: Bool
    let onSubmit: () -> Void

    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LanguageSelectorView(
                mode: .source,
                selectedLanguage: $sourceLanguage,
                detectedLanguage: detectedLanguage,
                isAutoDetect: $isAutoDetect
            )
            .padding(.leading, GlimpseTheme.Spacing.lg)
            .padding(.top, GlimpseTheme.Spacing.lg)

            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    if inputText.isEmpty {
                        Text("Enter text...")
                            .font(GlimpseTheme.Typography.body)
                            .foregroundStyle(GlimpseTheme.Colors.placeholderText)
                            .padding(.leading, 5)  // Match TextEditor's internal padding
                            .padding(.top, 8)      // Match TextEditor's internal padding
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $inputText)
                        .font(GlimpseTheme.Typography.body)
                        .foregroundStyle(GlimpseTheme.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .fixedSize(horizontal: false, vertical: true)
                        .focused($isInputFocused)
                        .accessibilityLabel("Text to translate")
                        .accessibilityHint("Enter text you want to translate")
                }
                .padding(.horizontal, GlimpseTheme.Spacing.lg)
                .padding(.top, GlimpseTheme.Spacing.md)
            }
            .frame(maxHeight: GlimpseTheme.Sizing.maxTextAreaHeight)
            .fadingScrollbar()

            SettingsLink {
                EmptyView()
            }
                .buttonStyle(SettingsButtonStyle())
                .padding(.leading, GlimpseTheme.Spacing.sm)
                .padding(.bottom, GlimpseTheme.Spacing.sm)
        }
        .frame(width: GlimpseTheme.Sizing.columnWidth)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                .fill(GlimpseTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                        .strokeBorder(GlimpseTheme.Colors.cardBorder, lineWidth: 1)
                )
        )
        .onAppear {
            isInputFocused = true
        }
        .onSubmit(onSubmit)
    }
}

#Preview {
    HStack(spacing: GlimpseTheme.Spacing.xs) {
        SourceColumnView(
            inputText: .constant(""),
            sourceLanguage: .constant(.english),
            detectedLanguage: nil,
            isAutoDetect: .constant(true),
            onSubmit: {}
        )

        SourceColumnView(
            inputText: .constant("Hello, how are you today?"),
            sourceLanguage: .constant(.english),
            detectedLanguage: .english,
            isAutoDetect: .constant(true),
            onSubmit: {}
        )
    }
    .frame(height: GlimpseTheme.Sizing.contentHeight)
    .padding(GlimpseTheme.Spacing.xs)
    .background(GlimpseTheme.Colors.containerBackground)
}
