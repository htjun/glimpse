//
//  SwapButtonStyle.swift
//  Glimpse
//

import SwiftUI

/// Circular button style for the language swap button.
struct SwapButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isEnabled ? .primary : .secondary)
            .frame(
                width: GlimpseTheme.Sizing.swapButtonSize,
                height: GlimpseTheme.Sizing.swapButtonSize
            )
            .background(
                Circle()
                    .fill(configuration.isPressed
                        ? GlimpseTheme.Colors.buttonPressedBackground
                        : GlimpseTheme.Colors.swapButtonBackground)
            )
            .overlay(
                Circle()
                    .strokeBorder(GlimpseTheme.Colors.buttonBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: 20) {
        Button(action: {}) {
            Image(systemName: "arrow.left.arrow.right")
        }
        .buttonStyle(SwapButtonStyle())

        Button(action: {}) {
            Image(systemName: "arrow.left.arrow.right")
        }
        .buttonStyle(SwapButtonStyle())
        .disabled(true)
    }
    .padding()
}
