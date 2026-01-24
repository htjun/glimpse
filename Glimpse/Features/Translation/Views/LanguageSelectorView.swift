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
    let isAutoDetect: Bool

    // MARK: - Body

    var body: some View {
        Menu {
            if mode == .source {
                Button {
                    // Auto-detect is handled by parent via isAutoDetect binding
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
                } label: {
                    HStack {
                        Text(language.displayName)
                        if !isAutoDetect && selectedLanguage == language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            menuLabel
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - View Components

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
        .background(
            RoundedRectangle(cornerRadius: GlimpseTheme.Radii.small)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch mode {
        case .source:
            return isAutoDetect ? "sparkles" : "text.bubble"
        case .target:
            return "text.bubble.fill"
        }
    }

    private var iconColor: Color {
        switch mode {
        case .source:
            return isAutoDetect ? .blue : .primary
        case .target:
            return .primary
        }
    }

    private var displayText: String {
        switch mode {
        case .source:
            if isAutoDetect {
                if let detected = detectedLanguage {
                    return "\(detected.displayName) - Detected"
                }
                return "Detect Language"
            }
            return selectedLanguage.displayName
        case .target:
            return selectedLanguage.displayName
        }
    }

    private var accessibilityLabel: String {
        switch mode {
        case .source:
            return "Source language: \(displayText)"
        case .target:
            return "Target language: \(selectedLanguage.displayName)"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LanguageSelectorView(
            mode: .source,
            selectedLanguage: .constant(.english),
            detectedLanguage: nil,
            isAutoDetect: true
        )

        LanguageSelectorView(
            mode: .source,
            selectedLanguage: .constant(.english),
            detectedLanguage: .korean,
            isAutoDetect: true
        )

        LanguageSelectorView(
            mode: .target,
            selectedLanguage: .constant(.korean),
            detectedLanguage: nil,
            isAutoDetect: false
        )
    }
    .padding()
}
