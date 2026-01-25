//
//  Theme.swift
//  Glimpse
//

import SwiftUI

/// Centralized design tokens for Glimpse UI.
enum GlimpseTheme {

    // MARK: - Colors

    enum Colors {
        // MARK: New Panel Design Colors

        /// Container background - warm light gray (#F4F2F0)
        static let containerBackground = Color(red: 244 / 255, green: 242 / 255, blue: 240 / 255)

        /// Card background - warm off-white (#FDFCF9)
        static let cardBackground = Color(red: 253 / 255, green: 252 / 255, blue: 249 / 255)

        /// Card border color (#D9D9D1)
        static let cardBorder = Color(red: 217 / 255, green: 217 / 255, blue: 209 / 255)

        /// Container border
        static let containerBorder = Color.black.opacity(0.1)

        /// Primary text color - dark brown-black (#26251E)
        static let textPrimary = Color(red: 38 / 255, green: 37 / 255, blue: 30 / 255)

        /// Secondary text color
        static let textSecondary = Color.black.opacity(0.5)

        /// Tertiary text color
        static let textTertiary = Color.black.opacity(0.6)

        /// Icon background (#EFEEEB)
        static let iconBackground = Color(red: 239 / 255, green: 238 / 255, blue: 235 / 255)

        /// Button background
        static let buttonBackground = Color.white.opacity(0.6)

        /// Placeholder text color
        static let placeholderText = Color.black.opacity(0.3)

        // MARK: Semantic Colors

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
        static let container: CGFloat = 12
    }

    // MARK: - Typography

    enum Typography {
        private static let fontFamily = "Geist"

        /// Body text - 18px for main content
        static let body = Font.custom("\(fontFamily)-Regular", size: 18, relativeTo: .body)

        /// UI label text - 14px medium for selectors
        static let uiLabel = Font.custom("\(fontFamily)-Medium", size: 14, relativeTo: .callout)

        /// Caption text - 14px for secondary content
        static let caption = Font.custom("\(fontFamily)-Regular", size: 14, relativeTo: .callout)

        /// Footnote text - 12px medium
        static let footnote = Font.custom("\(fontFamily)-Medium", size: 12, relativeTo: .footnote)

        /// Button text - 13px medium
        static let button = Font.custom("\(fontFamily)-Medium", size: 13, relativeTo: .subheadline)
    }

    // MARK: - Sizing

    enum Sizing {
        // MARK: New Panel Design Sizing

        /// Outer container width (includes padding)
        static let containerWidth: CGFloat = 747

        /// Content width inside container
        static let contentWidth: CGFloat = 731

        /// Content height
        static let contentHeight: CGFloat = 400

        /// Width for each column
        static let columnWidth: CGFloat = 365

        /// Inner padding between container edge and content
        static let innerPadding: CGFloat = 4

        /// Padding inside the card
        static let cardPadding: CGFloat = 16

        /// Outer padding around container
        static let outerPadding: CGFloat = 4

        /// Maximum height for scrollable text areas
        static let maxTextAreaHeight: CGFloat = 800
    }
}
