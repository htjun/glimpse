//
//  TranslationBackend.swift
//  Glimpse
//

import Foundation

// MARK: - Translation Result

/// Result of a translation operation.
struct TranslationResult: Sendable {
    let translatedText: String
    let detectedSourceLanguage: SupportedLanguage?
}

// MARK: - Translation Backend Error

/// Errors that can occur during translation.
enum TranslationBackendError: Error, LocalizedError {
    case noTranslationFound
    case translationFailed(underlying: Error?)
    case modelNotLoaded
    case modelNotDownloaded
    case unsupportedLanguagePair(source: SupportedLanguage, target: SupportedLanguage)

    var errorDescription: String? {
        switch self {
        case .noTranslationFound:
            return "No translation found"
        case .translationFailed(let underlying):
            if let underlying {
                return "Translation failed: \(underlying.localizedDescription)"
            }
            return "Translation failed"
        case .modelNotLoaded:
            return "Translation model not loaded. Please load it in Settings."
        case .modelNotDownloaded:
            return "Translation model not downloaded. Please download it in Settings."
        case .unsupportedLanguagePair(let source, let target):
            return "Unsupported language pair: \(source.displayName) to \(target.displayName)"
        }
    }
}

// MARK: - Translation Backend Protocol

/// Protocol for translation backends (Apple API, Local LLM, etc.)
@MainActor
protocol TranslationBackend: Sendable {
    /// Unique identifier for this backend
    var identifier: String { get }

    /// Human-readable name for display
    var displayName: String { get }

    /// Whether this backend is ready to perform translations
    var isReady: Bool { get }

    /// Translates text from source to target language
    /// - Parameters:
    ///   - text: The text to translate
    ///   - source: Source language (nil for auto-detect)
    ///   - target: Target language
    /// - Returns: Translation result with translated text and detected source language
    func translate(
        text: String,
        from source: SupportedLanguage?,
        to target: SupportedLanguage
    ) async throws -> TranslationResult
}
