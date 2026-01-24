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
        HStack(spacing: GlimpseTheme.Spacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)

            Text(displayText)
                .font(GlimpseTheme.Typography.caption)
                .foregroundStyle(.primary)

            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, GlimpseTheme.Spacing.md)
        .padding(.vertical, GlimpseTheme.Spacing.sm)
        .contentShape(Rectangle())
    }

    // MARK: - Computed Properties

    private var isSourceMode: Bool {
        mode == .source
    }

    private var iconName: String {
        if mode == .target {
            return "text.bubble.fill"
        }
        return isAutoDetect ? "sparkles" : "text.bubble"
    }

    private var iconColor: Color {
        isSourceMode && isAutoDetect ? .blue : .primary
    }

    private var displayText: String {
        if isSourceMode && isAutoDetect {
            if let detected = detectedLanguage {
                return "\(detected.displayName) - Detected"
            }
            return "Detect Language"
        }
        return selectedLanguage.displayName
    }

    private var accessibilityLabel: String {
        let prefix = isSourceMode ? "Source" : "Target"
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
}
