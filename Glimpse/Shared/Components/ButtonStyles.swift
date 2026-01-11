//
//  ButtonStyles.swift
//  Glimpse
//

import SwiftUI

/// Primary button style - dark filled with white uppercase text.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textCase(.uppercase)
            .font(GlimpseTheme.Typography.buttonPrimary)
            .tracking(0.5)
            .foregroundColor(.white)
            .padding(.horizontal, GlimpseTheme.Spacing.lg)
            .frame(height: GlimpseTheme.Sizing.primaryButtonHeight)
            .frame(minWidth: GlimpseTheme.Sizing.primaryButtonMinWidth)
            .background(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                    .strokeBorder(GlimpseTheme.Colors.panelBackground, lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled { return .gray }
        return isPressed ? Color.black.opacity(0.7) : .black
    }
}

/// Loading button style - outlined with dark text for translating state.
struct LoadingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textCase(.uppercase)
            .font(GlimpseTheme.Typography.buttonPrimary)
            .tracking(0.5)
            .foregroundColor(GlimpseTheme.Colors.textDisabled)
            .padding(.horizontal, GlimpseTheme.Spacing.lg)
            .frame(height: GlimpseTheme.Sizing.primaryButtonHeight)
            .frame(minWidth: GlimpseTheme.Sizing.primaryButtonMinWidth)
            .background(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                    .strokeBorder(GlimpseTheme.Colors.buttonBorder, lineWidth: 1)
            )
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
                    .fill(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlimpseTheme.Radii.small)
                    .stroke(GlimpseTheme.Colors.buttonBorder, lineWidth: 1)
            )
    }
}
