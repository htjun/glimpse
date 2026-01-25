//
//  LocalLLMTranslationBackend.swift
//  Glimpse
//

import Foundation
import NaturalLanguage
import os.log

/// Result from streaming translation, containing the text stream and detected source language.
struct StreamingTranslationResult: Sendable {
    /// Async stream of translated text chunks (accumulated, not incremental).
    let textStream: AsyncStream<String>

    /// The detected source language, if auto-detection was used.
    let detectedSourceLanguage: SupportedLanguage?
}

/// Translation backend using local TranslateGemma model.
@MainActor
final class LocalLLMTranslationBackend: TranslationBackend, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = LocalLLMTranslationBackend()

    // MARK: - Properties

    let identifier = "localLLM"
    let displayName = "TranslateGemma (Local)"

    var isReady: Bool {
        LocalLLMService.shared.modelState.isReady
    }

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Glimpse",
        category: "LocalLLMTranslationBackend"
    )

    // MARK: - Initialization

    private init() {}

    // MARK: - TranslationBackend

    func translate(
        text: String,
        from source: SupportedLanguage?,
        to target: SupportedLanguage
    ) async throws -> TranslationResult {
        // Wait for model to be ready (handles loading state)
        if !isReady {
            try await ensureModelReady()
        }

        // Detect source language if not provided
        let effectiveSource = source ?? detectLanguage(text) ?? .english

        logger.info("Translating with LocalLLM from \(effectiveSource.displayName) to \(target.displayName)")

        let translatedText = try await LocalLLMService.shared.translate(
            text: text,
            from: effectiveSource,
            to: target
        )

        if translatedText.isEmpty || translatedText == text {
            throw TranslationBackendError.noTranslationFound
        }

        return TranslationResult(
            translatedText: translatedText,
            detectedSourceLanguage: source == nil ? effectiveSource : nil
        )
    }

    // MARK: - Private Methods

    /// Ensures the model is ready, waiting if necessary.
    private func ensureModelReady() async throws {
        switch LocalLLMService.shared.modelState {
        case .notDownloaded:
            throw TranslationBackendError.modelNotDownloaded
        case .error:
            throw TranslationBackendError.modelNotLoaded
        case .ready:
            return
        case .loading, .downloading, .downloaded:
            logger.info("Waiting for model to become ready...")
            guard await LocalLLMService.shared.waitForReady(timeout: 60) else {
                throw TranslationBackendError.modelNotLoaded
            }
        }
    }

    private func detectLanguage(_ text: String) -> SupportedLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let detected = recognizer.dominantLanguage else { return nil }
        return SupportedLanguage.allCases.first { $0.rawValue == detected.rawValue }
    }

    // MARK: - Streaming Translation

    #if canImport(MLXLLM)
    /// Translates text with streaming output for real-time UI updates.
    ///
    /// - Parameters:
    ///   - text: The text to translate.
    ///   - source: Optional source language. If nil, auto-detects the language.
    ///   - target: The target language for translation.
    /// - Returns: A StreamingTranslationResult containing the text stream and detected language.
    func translateStreaming(
        text: String,
        from source: SupportedLanguage?,
        to target: SupportedLanguage
    ) async throws -> StreamingTranslationResult {
        // Wait for model to be ready
        if !isReady {
            try await ensureModelReady()
        }

        // Detect source language if not provided
        let effectiveSource = source ?? detectLanguage(text) ?? .english
        let detectedLanguage = source == nil ? effectiveSource : nil

        logger.info(
            "Starting streaming translation from \(effectiveSource.displayName) to \(target.displayName)"
        )

        let textStream = try await LocalLLMService.shared.translateStreaming(
            text: text,
            from: effectiveSource,
            to: target
        )

        return StreamingTranslationResult(
            textStream: textStream,
            detectedSourceLanguage: detectedLanguage
        )
    }
    #endif
}
