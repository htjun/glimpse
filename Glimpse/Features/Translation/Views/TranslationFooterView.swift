//
//  TranslationFooterView.swift
//  Glimpse
//

import SwiftUI

/// Footer view with app branding and copy action.
struct TranslationFooterView: View {

    // MARK: - Properties

    let hasTranslation: Bool
    let onCopy: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            // Left: App branding
            HStack(spacing: GlimpseTheme.Spacing.sm) {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text("Translate")
                    .font(GlimpseTheme.Typography.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right: Copy button with shortcut hint
            if hasTranslation {
                Button(action: onCopy) {
                    HStack(spacing: GlimpseTheme.Spacing.xs) {
                        Text("Copy Translation")
                        Text("\u{2318}\u{21A9}")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityLabel("Copy translation")
                .accessibilityHint("Press Command+Return to copy the translation to clipboard")
            }
        }
        .padding(.horizontal, GlimpseTheme.Spacing.lg)
        .frame(height: GlimpseTheme.Sizing.footerHeight)
        .background(GlimpseTheme.Colors.headerBackground)
    }
}

#Preview {
    VStack(spacing: 20) {
        TranslationFooterView(hasTranslation: false, onCopy: {})
            .background(Color.gray.opacity(0.1))

        TranslationFooterView(hasTranslation: true, onCopy: {})
            .background(Color.gray.opacity(0.1))
    }
    .frame(width: GlimpseTheme.Sizing.twoColumnPanelWidth)
}
