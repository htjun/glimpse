//
//  LanguageSelectorView.swift
//  Glimpse
//

import SwiftUI

/// Mode for the language selector (source or target).
enum LanguageSelectorMode {
    case source
    case target
}

/// Dropdown component for selecting source or target language.
/// Simplified design with text + chevron only.
struct LanguageSelectorView: View {

    // MARK: - Properties

    let mode: LanguageSelectorMode
    @Binding var selectedLanguage: SupportedLanguage
    let detectedLanguage: SupportedLanguage?
    @Binding var isAutoDetect: Bool

    // MARK: - Body

    var body: some View {
        Menu {
            menuContent
        } label: {
            menuLabel
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - View Components

    @ViewBuilder
    private var menuContent: some View {
        if mode == .source {
            Button {
                isAutoDetect = true
            } label: {
                HStack {
                    Text("Detect Language")
                    if isAutoDetect {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Divider()
        }

        ForEach(SupportedLanguage.allCases) { language in
            Button {
                selectedLanguage = language
                if mode == .source {
                    isAutoDetect = false
                }
            } label: {
                HStack {
                    Text(language.displayName)
                    if !isAutoDetect && selectedLanguage == language {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }

    private var menuLabel: some View {
        HStack(spacing: GlimpseTheme.Spacing.xs) {
            Text(displayText)
                .font(GlimpseTheme.Typography.uiLabel)
                .foregroundStyle(GlimpseTheme.Colors.textSecondary)

            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.3))
        }
        .contentShape(Rectangle())
    }

    // MARK: - Computed Properties

    private var displayText: String {
        if mode == .source && isAutoDetect {
            if let detected = detectedLanguage {
                return "\(detected.displayName) - Detected"
            }
            return "Detect Language"
        }
        return selectedLanguage.displayName
    }

    private var accessibilityLabel: String {
        let prefix = mode == .source ? "Source" : "Target"
        return "\(prefix) language: \(displayText)"
    }
}

#Preview {
    VStack(spacing: 20) {
        LanguageSelectorView(
            mode: .source,
            selectedLanguage: .constant(.english),
            detectedLanguage: nil,
            isAutoDetect: .constant(true)
        )

        LanguageSelectorView(
            mode: .source,
            selectedLanguage: .constant(.english),
            detectedLanguage: .korean,
            isAutoDetect: .constant(true)
        )

        LanguageSelectorView(
            mode: .target,
            selectedLanguage: .constant(.korean),
            detectedLanguage: nil,
            isAutoDetect: .constant(false)
        )
    }
    .padding()
    .background(GlimpseTheme.Colors.containerBackground)
}
