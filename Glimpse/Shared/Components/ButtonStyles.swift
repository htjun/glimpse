//
//  ButtonStyles.swift
//  Glimpse
//

import SwiftUI

/// Primary button style - dark filled with white uppercase text.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textCase(.uppercase)
            .font(.system(size: 13, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(.white)
            .frame(width: 130, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.black.opacity(0.7) : Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(red: 247 / 255, green: 247 / 255, blue: 244 / 255), lineWidth: 1)
            )
    }
}

/// Loading button style - outlined with dark text for translating state.
struct LoadingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textCase(.uppercase)
            .font(.system(size: 13, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(.primary.opacity(0.6))
            .frame(width: 130, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
            )
    }
}

/// Secondary button style - small outlined for action buttons (Copy/Replace).
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textCase(.uppercase)
            .font(.system(size: 11, weight: .medium))
            .tracking(0.3)
            .foregroundColor(configuration.isPressed ? .secondary : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}
