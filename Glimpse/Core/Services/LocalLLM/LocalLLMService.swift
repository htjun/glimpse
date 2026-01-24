//
//  LocalLLMService.swift
//  Glimpse
//

import Foundation
import os.log
import SwiftUI

#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon
#endif

/// Service for managing and running local LLM translation models.
@MainActor @Observable
final class LocalLLMService {

    // MARK: - Singleton

    static let shared = LocalLLMService()

    // MARK: - Properties

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Glimpse",
        category: "LocalLLMService"
    )

    /// Current state of the selected model
    private(set) var modelState: LocalLLMModelState = .notDownloaded

    /// Download progress (0.0 to 1.0)
    private(set) var downloadProgress: Double = 0

    #if canImport(MLXLLM)
    /// Currently loaded model container
    private var modelContainer: ModelContainer?
    #endif

    /// Selected model (persisted)
    var selectedModel: LocalLLMModel {
        get {
            LocalLLMModel(rawValue: selectedModelId) ?? .translateGemma4B
        }
        set {
            selectedModelId = newValue.rawValue
            // Reset state when model changes
            Task { await checkModelStatus() }
        }
    }

    @ObservationIgnored
    @AppStorage(LocalLLMSettingsKey.selectedModel)
    private var selectedModelId: String = LocalLLMModel.translateGemma4B.rawValue

    @ObservationIgnored
    @AppStorage(LocalLLMSettingsKey.wasModelLoaded)
    private var wasModelLoaded: Bool = false

    // MARK: - Initialization

    private init() {
        Task { await checkModelStatus() }
    }

    // MARK: - Public Methods

    /// Checks if the selected model is downloaded.
    func checkModelStatus() async {
        let modelPath = modelDirectoryPath(for: selectedModel)
        if FileManager.default.fileExists(atPath: modelPath.path) {
            modelState = .downloaded
            logger.info("Model found at: \(modelPath.path)")
        } else {
            modelState = .notDownloaded
            logger.info("Model not found at: \(modelPath.path)")
        }
    }

    /// Downloads the selected model from Hugging Face.
    func downloadModel() async throws {
        guard modelState == .notDownloaded || modelState.isDownloading == false else {
            logger.warning("Download already in progress or model already downloaded")
            return
        }

        #if canImport(MLXLLM)
        modelState = .downloading(progress: 0)
        downloadProgress = 0

        logger.info("Starting download of \(self.selectedModel.displayName)")

        let configuration = ModelConfiguration(id: selectedModel.huggingFaceId)

        do {
            // Configure GPU cache limit (20MB as per MLX examples)
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

            modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: configuration
            ) { [weak self] progress in
                Task { @MainActor in
                    guard let self else { return }
                    self.downloadProgress = progress.fractionCompleted
                    self.modelState = .downloading(progress: progress.fractionCompleted)
                }
            }

            modelState = .ready
            wasModelLoaded = true
            logger.info("Model download and load complete")

        } catch {
            logger.error("Model download failed: \(error.localizedDescription)")
            modelState = .error(error.localizedDescription)
            throw error
        }
        #else
        logger.error("MLX packages not available")
        modelState = .error("MLX packages not installed. Please add MLX Swift LM dependency.")
        throw TranslationBackendError.modelNotDownloaded
        #endif
    }

    /// Loads an already-downloaded model.
    func loadModel() async throws {
        guard modelState == .downloaded else {
            if modelState == .ready { return }
            throw TranslationBackendError.modelNotDownloaded
        }

        #if canImport(MLXLLM)
        modelState = .loading
        logger.info("Loading model \(self.selectedModel.displayName)")

        let configuration = ModelConfiguration(id: selectedModel.huggingFaceId)

        do {
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

            modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: configuration
            ) { _ in }

            modelState = .ready
            wasModelLoaded = true
            logger.info("Model loaded successfully")

        } catch {
            logger.error("Model loading failed: \(error.localizedDescription)")
            modelState = .error(error.localizedDescription)
            throw error
        }
        #else
        logger.error("MLX packages not available")
        modelState = .error("MLX packages not installed")
        throw TranslationBackendError.modelNotLoaded
        #endif
    }

    /// Auto-loads the model if downloaded.
    func autoLoadIfNeeded() async {
        // First ensure we have current status
        await checkModelStatus()

        // Only auto-load if model is downloaded (files exist)
        guard modelState == .downloaded else { return }

        logger.info("Auto-loading downloaded model")
        do {
            try await loadModel()
        } catch {
            logger.error("Auto-load failed: \(error.localizedDescription)")
        }
    }

    /// Waits for the model to become ready (with timeout).
    /// Returns true if model is ready, false if timeout or error.
    func waitForReady(timeout: TimeInterval = 60) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            switch modelState {
            case .ready:
                return true
            case .loading, .downloading:
                // Still loading, wait and check again
                try? await Task.sleep(for: .milliseconds(100))
            case .downloaded:
                // Model downloaded but not loading - trigger load
                do {
                    try await loadModel()
                    return modelState == .ready
                } catch {
                    return false
                }
            case .notDownloaded, .error:
                return false
            }
        }

        logger.warning("Timeout waiting for model to be ready")
        return false
    }

    /// Unloads the current model to free memory.
    func unloadModel() {
        #if canImport(MLXLLM)
        modelContainer = nil
        #endif
        modelState = .downloaded
        wasModelLoaded = false
        logger.info("Model unloaded")
    }

    /// Deletes the downloaded model.
    func deleteModel() throws {
        unloadModel()

        let modelPath = modelDirectoryPath(for: selectedModel)

        if FileManager.default.fileExists(atPath: modelPath.path) {
            try FileManager.default.removeItem(at: modelPath)
            logger.info("Model deleted at: \(modelPath.path)")
        }

        modelState = .notDownloaded
        logger.info("Model deleted")
    }

    /// Generates translation using TranslateGemma with manual prompt construction.
    ///
    /// Note: We bypass `applyChatTemplate()` because swift-transformers 1.1.6 doesn't support
    /// loading external `chat_template.jinja` files. TranslateGemma stores its complex template
    /// (17KB with 600+ language mappings) in an external file, causing the library to fall back
    /// to a generic Gemma template that produces malformed prompts.
    ///
    /// Instead, we manually construct prompts using Gemma 3's chat format.
    /// See: https://github.com/huggingface/swift-transformers/issues/204
    func translate(
        text: String,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) async throws -> String {
        #if canImport(MLXLLM)
        guard let container = modelContainer, modelState == .ready else {
            throw TranslationBackendError.modelNotLoaded
        }

        // Build prompt manually using Gemma 3 chat format
        let prompt = buildTranslateGemmaPrompt(text: text, from: source, to: target)

        logger.info("Starting translation generation...")
        logger.debug("Prompt: \(prompt)")

        let result = try await container.perform { [logger] context in
            // Tokenize the prompt directly instead of using processor.prepare()
            let tokens = context.tokenizer.encode(text: prompt)
            let input = LMInput(tokens: MLXArray(tokens))

            logger.debug("Input prepared (\(tokens.count) tokens), starting generation...")

            var generatedText = ""
            var tokenCount = 0
            _ = try MLXLMCommon.generate(
                input: input,
                parameters: GenerateParameters(maxTokens: 512, temperature: 0.3),
                context: context
            ) { tokens in
                tokenCount = tokens.count
                generatedText = context.tokenizer.decode(tokens: tokens)

                // Stop early if we detect end-of-turn token
                if generatedText.contains("<end_of_turn>") {
                    return .stop
                }

                return .more
            }

            logger.debug("Generation complete: \(tokenCount) tokens")
            return generatedText
        }

        let translation = extractTranslation(from: result)
        logger.info("Translation completed: \(translation.prefix(50))...")
        return translation
        #else
        throw TranslationBackendError.modelNotLoaded
        #endif
    }

    // MARK: - Private Methods

    /// Builds a TranslateGemma prompt using Gemma 3 chat format.
    ///
    /// Format:
    /// ```
    /// <start_of_turn>user
    /// Translate from [Source] to [Target]. Output only the translation.
    ///
    /// [text]<end_of_turn>
    /// <start_of_turn>model
    /// ```
    ///
    /// The language display names (e.g., "English", "Korean", "Chinese (Simplified)")
    /// are compatible with TranslateGemma per the official documentation.
    private func buildTranslateGemmaPrompt(
        text: String,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) -> String {
        """
        <start_of_turn>user
        Translate from \(source.displayName) to \(target.displayName). Output only the translation.

        \(text)<end_of_turn>
        <start_of_turn>model
        """
    }

    private func modelDirectoryPath(for model: LocalLLMModel) -> URL {
        // MLX Swift LM uses HubApi with downloadBase = ~/Library/Caches/
        // HubApi stores models at: downloadBase/models/repo-id
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir
            .appendingPathComponent("models")
            .appendingPathComponent(model.huggingFaceId)
    }

    /// Cleans up the generated output by removing special tokens.
    private func extractTranslation(from output: String) -> String {
        var result = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove end-of-turn token if present
        if let range = result.range(of: "<end_of_turn>") {
            result = String(result[..<range.lowerBound])
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
