//
//  TargetColumnView.swift
//  Glimpse
//

import SwiftUI

/// Right column with translation output.
/// Contains embedded language selector and copy button. Transparent background.
struct TargetColumnView: View {

    // MARK: - Properties

    let translatedText: String
    let isTranslating: Bool
    let error: String?
    @Binding var targetLanguage: SupportedLanguage
    let hasTranslation: Bool
    let onCopy: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Language selector (top-left)
            LanguageSelectorView(
                mode: .target,
                selectedLanguage: $targetLanguage,
                detectedLanguage: nil,
                isAutoDetect: .constant(false)
            )
            .padding(.leading, GlimpseTheme.Spacing.lg)
            .padding(.top, GlimpseTheme.Spacing.lg)

            // Translation output area (scrollable)
            ScrollView(.vertical, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    if isTranslating {
                        loadingView
                    } else if let error {
                        errorView(error)
                    } else if translatedText.isEmpty {
                        placeholderView
                    } else {
                        resultView
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, GlimpseTheme.Spacing.lg)
                .padding(.top, GlimpseTheme.Spacing.md)
            }
            .frame(maxHeight: GlimpseTheme.Sizing.maxTextAreaHeight)

            // Copy button (bottom-right)
            if hasTranslation {
                HStack {
                    Spacer()
                    Button(action: onCopy) {}
                        .buttonStyle(CopyButtonStyle())
                        .accessibilityLabel("Copy translation")
                        .accessibilityHint("Press Command+Return to copy the translation to clipboard")
                }
                .padding(.trailing, GlimpseTheme.Spacing.sm)
                .padding(.bottom, GlimpseTheme.Spacing.sm)
            }
        }
        .frame(width: GlimpseTheme.Sizing.columnWidth)
        .frame(maxHeight: .infinity)
        // No background - transparent
    }

    // MARK: - View Components

    private var placeholderView: some View {
        Text("Translation")
            .font(GlimpseTheme.Typography.body)
            .foregroundStyle(GlimpseTheme.Colors.placeholderText)
    }

    private var loadingView: some View {
        HStack(spacing: GlimpseTheme.Spacing.sm) {
            ProgressView()
                .controlSize(.small)
            Text("Translating...")
                .font(GlimpseTheme.Typography.body)
                .foregroundStyle(GlimpseTheme.Colors.textDisabled)
        }
    }

    private var resultView: some View {
        Text(translatedText)
            .font(GlimpseTheme.Typography.body)
            .foregroundStyle(GlimpseTheme.Colors.textPrimary)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func errorView(_ message: String) -> some View {
        HStack(spacing: GlimpseTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GlimpseTheme.Colors.errorIcon)
                .accessibilityHidden(true)
            Text(message)
                .font(GlimpseTheme.Typography.uiLabel)
                .foregroundStyle(.secondary)
        }
        .padding(GlimpseTheme.Spacing.md)
        .background(GlimpseTheme.Colors.errorBackground)
        .clipShape(RoundedRectangle(cornerRadius: GlimpseTheme.Radii.small))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

#Preview {
    HStack(spacing: GlimpseTheme.Spacing.xs) {
        TargetColumnView(
            translatedText: "",
            isTranslating: false,
            error: nil,
            targetLanguage: .constant(.korean),
            hasTranslation: false,
            onCopy: {}
        )

        TargetColumnView(
            translatedText: "",
            isTranslating: true,
            error: nil,
            targetLanguage: .constant(.korean),
            hasTranslation: false,
            onCopy: {}
        )

        TargetColumnView(
            translatedText: "안녕하세요, 오늘 어떻게 지내세요?",
            isTranslating: false,
            error: nil,
            targetLanguage: .constant(.korean),
            hasTranslation: true,
            onCopy: {}
        )
    }
    .frame(height: GlimpseTheme.Sizing.contentHeight)
    .padding(GlimpseTheme.Spacing.xs)
    .background(GlimpseTheme.Colors.containerBackground)
}
