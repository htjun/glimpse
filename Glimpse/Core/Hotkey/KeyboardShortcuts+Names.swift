//
//  KeyboardShortcuts+Names.swift
//  Glimpse
//
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Global hotkey to toggle the translation panel (default: Cmd+Shift+Space)
    static let toggleTranslationPanel = Self(
        "toggleTranslationPanel",
        default: .init(.space, modifiers: [.command, .shift])
    )
}
