//
//  Theme.swift
//  Glimpse
//

import SwiftUI

/// Centralized design tokens for Glimpse UI.
enum GlimpseTheme {

    // MARK: - Colors

    enum Colors {
        /// Panel background - warm off-white
        static let panelBackground = Color(red: 247 / 255, green: 247 / 255, blue: 244 / 255)

        /// Panel border
        static let panelBorder = Color(red: 222 / 255, green: 221 / 255, blue: 217 / 255)

        /// Button border for secondary buttons
        static let buttonBorder = Color.gray.opacity(0.3)

        /// Disabled/loading text
        static let textDisabled = Color.primary.opacity(0.6)

        /// Error background tint
        static let errorBackground = Color.orange.opacity(0.1)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 30
    }

    // MARK: - Radii

    enum Radii {
        static let small: CGFloat = 6
        static let standard: CGFloat = 8
    }

    // MARK: - Typography

    enum Typography {
        static let body = Font.system(size: 16)
        static let caption = Font.system(size: 14)
        static let footnote = Font.system(size: 12, weight: .medium)
        static let buttonPrimary = Font.system(size: 13, weight: .semibold)
        static let buttonSecondary = Font.system(size: 11, weight: .medium)
    }

    // MARK: - Sizing

    enum Sizing {
        static let panelWidth: CGFloat = 480
        static let panelMaxHeight: CGFloat = 800
        static let primaryButtonHeight: CGFloat = 32
        static let primaryButtonMinWidth: CGFloat = 100
    }
}
