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
                errorSection(error)
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

    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(error)
                .font(GlimpseTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(GlimpseTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlimpseTheme.Colors.errorBackground)
        .clipShape(RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard))
    }
}

#Preview {
    VStack(spacing: 20) {
        TranslationResultView(result: "Hello, world!", error: nil)
        TranslationResultView(result: "", error: "Translation failed: Network error")
    }
    .padding()
}
