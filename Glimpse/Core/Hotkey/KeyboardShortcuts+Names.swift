//
//  KeyboardShortcuts+Names.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Global hotkey to toggle the translation panel (default: Cmd+Shift+Space)
    static let toggleTranslationPanel = Self(
        "toggleTranslationPanel",
        default: .init(.space, modifiers: [.command, .shift])
    )
}
