//
//  ButtonStyles.swift
//  Glimpse
//

import SwiftUI

/// Settings button style (bottom-left of source column).
struct SettingsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: GlimpseTheme.Spacing.xs) {
            Image(systemName: "gearshape")
                .font(.system(size: 14))
                .foregroundStyle(GlimpseTheme.Colors.textSecondary)
            Text("Settings")
                .font(GlimpseTheme.Typography.button)
                .foregroundStyle(GlimpseTheme.Colors.textTertiary)
        }
        .padding(.horizontal, GlimpseTheme.Spacing.sm)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                .fill(configuration.isPressed ? Color.black.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

/// Copy button style with keyboard shortcut icons.
struct CopyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: GlimpseTheme.Spacing.sm) {
            Text("Copy Translation")
                .font(GlimpseTheme.Typography.button)
                .foregroundStyle(GlimpseTheme.Colors.textTertiary)

            HStack(spacing: GlimpseTheme.Spacing.xs) {
                KeyIcon(systemName: "command")
                KeyIcon(systemName: "return")
            }
        }
        .padding(.horizontal, GlimpseTheme.Spacing.md)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                .fill(GlimpseTheme.Colors.buttonBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GlimpseTheme.Radii.standard)
                        .strokeBorder(GlimpseTheme.Colors.cardBorder, lineWidth: 1)
                )
        )
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .contentShape(Rectangle())
    }
}

/// Small keyboard key icon used in button hints.
private struct KeyIcon: View {
    let systemName: String

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(GlimpseTheme.Colors.iconBackground)
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 10))
                    .foregroundStyle(GlimpseTheme.Colors.textSecondary)
            )
    }
}

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button(action: {}) {}
            .buttonStyle(SettingsButtonStyle())

        Button(action: {}) {}
            .buttonStyle(CopyButtonStyle())
    }
    .padding()
    .background(GlimpseTheme.Colors.containerBackground)
}
