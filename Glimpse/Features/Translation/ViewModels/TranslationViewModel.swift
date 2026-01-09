//
//  TranslationViewModel.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
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

    /// Indicates whether text capture is currently in progress.
    /// Used by TranslationPanelView to show a loading indicator.
    var isCapturingText: Bool = false

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

    /// Prepares for a new text capture cycle.
    /// Clears any previous captured text and signals that capture is in progress.
    func prepareForNewCapture() {
        capturedText = nil
        isCapturingText = true
    }

    /// Marks text capture as complete.
    func finishCapture() {
        isCapturingText = false
    }
}
