//
//  ButtonStyles.swift
//  Glimpse
//

import SwiftUI

/// Primary button style - configurable for normal and loading states.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textCase(.uppercase)
            .font(GlimpseTheme.Typography.buttonPrimary)
            .tracking(0.5)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, GlimpseTheme.Spacing.lg)
            .frame(height: GlimpseTheme.Sizing.primaryButtonHeight)
            .frame(minWidth: GlimpseTheme.Sizing.primaryButtonMinWidth)
            .background(
                Capsule()
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1)
            )
    }

    private var foregroundColor: Color {
        isLoading ? GlimpseTheme.Colors.textDisabled : .white
    }

    private var borderColor: Color {
        isLoading ? GlimpseTheme.Colors.buttonBorder : .clear
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isLoading { return GlimpseTheme.Colors.panelBackground }
        if !isEnabled { return GlimpseTheme.Colors.buttonDisabled }
        return isPressed ? Color.black.opacity(0.7) : .black
    }
}

/// Secondary button style - small outlined for action buttons (Copy/Replace).
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textCase(.uppercase)
            .font(GlimpseTheme.Typography.buttonSecondary)
            .tracking(0.3)
            .foregroundColor(configuration.isPressed ? .secondary : .primary)
            .padding(.horizontal, GlimpseTheme.Spacing.md)
            .padding(.vertical, GlimpseTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.small)
                    .fill(configuration.isPressed ? GlimpseTheme.Colors.buttonPressedBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.small)
                    .stroke(GlimpseTheme.Colors.buttonBorder, lineWidth: 1)
            )
    }
}
