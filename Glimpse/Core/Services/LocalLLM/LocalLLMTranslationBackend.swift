//
//  LocalLLMTranslationBackend.swift
//  Glimpse
//

import Foundation
import NaturalLanguage
import os.log

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
            let modelState = LocalLLMService.shared.modelState
            if modelState == .notDownloaded {
                throw TranslationBackendError.modelNotDownloaded
            }
            if case .error = modelState {
                throw TranslationBackendError.modelNotLoaded
            }

            // Model is loading or downloaded - wait for it to become ready
            logger.info("Waiting for model to become ready...")
            let ready = await LocalLLMService.shared.waitForReady(timeout: 60)
            if !ready {
                throw TranslationBackendError.modelNotLoaded
            }
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

    private func detectLanguage(_ text: String) -> SupportedLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let detected = recognizer.dominantLanguage else { return nil }
        return SupportedLanguage.allCases.first { $0.rawValue == detected.rawValue }
    }
}
