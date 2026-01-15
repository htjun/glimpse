//
//  TranslationResultView.swift
//  Glimpse
//

import SwiftUI

/// Displays translation result or error message.
struct TranslationResultView: View {

    // MARK: - Properties

    let result: String
    let error: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: GlimpseTheme.Spacing.lg) {
            if !result.isEmpty {
                resultSection
            }

            if let error {
                // Show as error style when there's no result (actual failure),
                // otherwise show as info style (e.g., "No translation found")
                messageSection(error, isError: result.isEmpty)
            }
        }
    }

    // MARK: - View Components

    private var resultSection: some View {
        Text(result)
            .font(GlimpseTheme.Typography.body)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }

    private func messageSection(_ message: String, isError: Bool) -> some View {
        HStack {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundStyle(isError ? GlimpseTheme.Colors.errorIcon : GlimpseTheme.Colors.infoIcon)
                .accessibilityHidden(true)
            Text(message)
                .font(GlimpseTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(GlimpseTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isError ? GlimpseTheme.Colors.errorBackground : GlimpseTheme.Colors.infoBackground)
        .clipShape(RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isError ? "Error: \(message)" : "Info: \(message)")
    }
}

#Preview {
    VStack(spacing: 20) {
        TranslationResultView(result: "Hello, world!", error: nil)
        TranslationResultView(result: "", error: "Translation failed")
        TranslationResultView(result: "", error: "No translation found")
    }
    .padding()
}
