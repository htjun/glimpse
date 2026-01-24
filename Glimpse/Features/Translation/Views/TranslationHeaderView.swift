//
//  TranslationHeaderView.swift
//  Glimpse
//

import SwiftUI

/// Header view with language dropdowns and swap button.
struct TranslationHeaderView: View {

    // MARK: - Properties

    @Binding var sourceLanguage: SupportedLanguage
    @Binding var targetLanguage: SupportedLanguage
    let detectedLanguage: SupportedLanguage?
    @Binding var isAutoDetect: Bool
    let onSwap: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            LanguageSelectorView(
                mode: .source,
                selectedLanguage: $sourceLanguage,
                detectedLanguage: detectedLanguage,
                isAutoDetect: $isAutoDetect
            )
            .frame(maxWidth: .infinity)

            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(SwapButtonStyle())
            .disabled(!canSwap)
            .accessibilityLabel("Swap languages")
            .accessibilityHint("Swaps source and target languages")

            LanguageSelectorView(
                mode: .target,
                selectedLanguage: $targetLanguage,
                detectedLanguage: nil,
                isAutoDetect: .constant(false)
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, GlimpseTheme.Spacing.md)
        .frame(height: GlimpseTheme.Sizing.headerHeight)
        .background(GlimpseTheme.Colors.headerBackground)
    }

    // MARK: - Computed Properties

    /// Can only swap if we have a detected language or explicit source selection
    private var canSwap: Bool {
        !isAutoDetect || detectedLanguage != nil
    }
}

#Preview {
    VStack(spacing: 0) {
        TranslationHeaderView(
            sourceLanguage: .constant(.english),
            targetLanguage: .constant(.korean),
            detectedLanguage: nil,
            isAutoDetect: .constant(true),
            onSwap: {}
        )

        Divider()

        TranslationHeaderView(
            sourceLanguage: .constant(.english),
            targetLanguage: .constant(.korean),
            detectedLanguage: .english,
            isAutoDetect: .constant(true),
            onSwap: {}
        )
    }
    .frame(width: GlimpseTheme.Sizing.twoColumnPanelWidth)
}
