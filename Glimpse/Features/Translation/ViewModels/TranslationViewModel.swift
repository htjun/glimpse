//
//  TranslationViewModel.swift
//  Glimpse
//
import Foundation

/// View model for the translation panel, holding shared state between hotkey handler and UI.
@MainActor @Observable
final class TranslationViewModel {

    // MARK: - Singleton

    static let shared = TranslationViewModel()

    // MARK: - Properties

    /// Text captured from another application when the hotkey was pressed.
    /// Set by AppDelegate before opening the panel, consumed by TranslationPanelView.
    var capturedText: String?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Consumes the captured text, returning it and clearing the stored value.
    /// This ensures the text is only used once when the panel opens.
    func consumeCapturedText() -> String? {
        let text = capturedText
        capturedText = nil
        return text
    }
}
