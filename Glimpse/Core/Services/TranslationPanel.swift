//
//  TranslationPanel.swift
//  Glimpse
//
import AppKit
import SwiftUI

/// Custom NSPanel subclass for chromeless floating translation panel.
/// Overrides canBecomeKey/canBecomeMain to enable keyboard input on borderless panel.
@MainActor
final class TranslationPanel: NSPanel {

    // MARK: - Properties

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // MARK: - Initialization

    init(contentView: NSView) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isMovableByWindowBackground = true
        backgroundColor = .clear
        hasShadow = false  // SwiftUI view provides its own shadow
        isOpaque = false

        self.contentView = contentView

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelSize = contentView.fittingSize
            let origin = NSPoint(
                x: screenFrame.midX - panelSize.width / 2,
                y: screenFrame.midY - panelSize.height / 2 + 100  // Slightly above center
            )
            setFrameOrigin(origin)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
