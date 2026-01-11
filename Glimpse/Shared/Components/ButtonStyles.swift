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
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.black.opacity(0.7) : Color.black)
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
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
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
