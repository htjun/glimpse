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

        /// Disabled button background
        static let buttonDisabled = Color(red: 203 / 255, green: 203 / 255, blue: 203 / 255)

        /// Secondary button pressed background
        static let buttonPressedBackground = Color.gray.opacity(0.1)

        /// Disabled/loading text
        static let textDisabled = Color.primary.opacity(0.6)

        /// Error icon color
        static let errorIcon = Color.orange

        /// Error background tint
        static let errorBackground = Color.orange.opacity(0.1)

        /// Info icon color
        static let infoIcon = Color.secondary

        /// Info background tint
        static let infoBackground = Color.secondary.opacity(0.1)

        // MARK: Two-Column Layout Colors

        /// Source column background - light blue tint
        static let sourceColumnBackground = Color(red: 240 / 255, green: 244 / 255, blue: 252 / 255)

        /// Target column background - warm cream
        static let targetColumnBackground = Color(red: 250 / 255, green: 249 / 255, blue: 246 / 255)

        /// Swap button background
        static let swapButtonBackground = Color(white: 0.95)

        /// Placeholder text color
        static let placeholderText = Color.gray.opacity(0.4)

        /// Header/footer background
        static let headerBackground = Color(white: 0.97)
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
        private static let fontFamily = "Geist"

        /// Body text with system font fallback
        static let body = Font.custom("\(fontFamily)-Regular", size: 16, relativeTo: .body)

        /// Caption text with system font fallback
        static let caption = Font.custom("\(fontFamily)-Regular", size: 14, relativeTo: .callout)

        /// Footnote text with system font fallback
        static let footnote = Font.custom("\(fontFamily)-Medium", size: 12, relativeTo: .footnote)

        /// Primary button text with system font fallback
        static let buttonPrimary = Font.custom("\(fontFamily)-SemiBold", size: 13, relativeTo: .subheadline)

        /// Secondary button text with system font fallback
        static let buttonSecondary = Font.custom("\(fontFamily)-Medium", size: 11, relativeTo: .caption)
    }

    // MARK: - Sizing

    enum Sizing {
        static let panelWidth: CGFloat = 480
        static let panelMaxHeight: CGFloat = 800
        static let primaryButtonHeight: CGFloat = 32
        static let primaryButtonMinWidth: CGFloat = 100

        // MARK: Two-Column Layout Sizing

        /// Width for the two-column panel
        static let twoColumnPanelWidth: CGFloat = 720

        /// Minimum width for each column
        static let columnMinWidth: CGFloat = 320

        /// Header height
        static let headerHeight: CGFloat = 48

        /// Footer height
        static let footerHeight: CGFloat = 44

        /// Swap button size
        static let swapButtonSize: CGFloat = 36

        /// Minimum height for text areas
        static let textAreaMinHeight: CGFloat = 280
    }
}
