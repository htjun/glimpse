//
//  TargetColumnView.swift
//  Glimpse
//

import SwiftUI

/// Right column with translation output.
struct TargetColumnView: View {

    // MARK: - Properties

    let translatedText: String
    let isTranslating: Bool
    let error: String?

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            GlimpseTheme.Colors.targetColumnBackground

            // Content
            VStack(alignment: .leading, spacing: GlimpseTheme.Spacing.md) {
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
            .padding(GlimpseTheme.Spacing.lg)
        }
        .frame(minWidth: GlimpseTheme.Sizing.columnMinWidth, minHeight: GlimpseTheme.Sizing.textAreaMinHeight)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: GlimpseTheme.Radii.standard,
                topTrailingRadius: 0
            )
        )
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
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func errorView(_ message: String) -> some View {
        HStack(spacing: GlimpseTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GlimpseTheme.Colors.errorIcon)
                .accessibilityHidden(true)
            Text(message)
                .font(GlimpseTheme.Typography.caption)
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
    HStack(spacing: 0) {
        TargetColumnView(
            translatedText: "",
            isTranslating: false,
            error: nil
        )

        TargetColumnView(
            translatedText: "",
            isTranslating: true,
            error: nil
        )

        TargetColumnView(
            translatedText: "Bonjour, comment allez-vous aujourd'hui?",
            isTranslating: false,
            error: nil
        )

        TargetColumnView(
            translatedText: "",
            isTranslating: false,
            error: "Translation failed"
        )
    }
    .frame(height: 300)
}
