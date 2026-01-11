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
            HStack(spacing: 12) {
                Button(action: onCopy) {
                    HStack(spacing: 4) {
                        Text("Copy")
                        Text("\u{2318}+C")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: onReplace) {
                    HStack(spacing: 4) {
                        Text("Replace")
                        Text("\u{2318}+R")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Spacer()

            Text("\(sourceLanguage.shortName) \u{2192} \(targetLanguage.shortName)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
