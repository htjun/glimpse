//
//  TranslationFooterView.swift
//  Glimpse
//

import SwiftUI

/// Footer view with copy/replace actions and language indicator.
struct TranslationFooterView: View {

    let sourceLanguage: SupportedLanguage
    let targetLanguage: SupportedLanguage
    let onCopy: () -> Void
    let onReplace: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: GlimpseTheme.Spacing.md) {
                ActionButton(title: "Copy", shortcut: "C", action: onCopy)
                ActionButton(title: "Replace", shortcut: "R", action: onReplace)
            }

            Spacer()

            Text("\(sourceLanguage.shortName) \u{2192} \(targetLanguage.shortName)")
                .font(GlimpseTheme.Typography.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let title: String
    let shortcut: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GlimpseTheme.Spacing.xs) {
                Text(title)
                Text("\u{2318}+\(shortcut)")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}
