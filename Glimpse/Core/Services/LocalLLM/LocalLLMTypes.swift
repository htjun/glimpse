//
//  LocalLLMTypes.swift
//  Glimpse
//

import Foundation

// MARK: - Local LLM Model

/// Available local LLM models for translation.
enum LocalLLMModel: String, CaseIterable, Identifiable, Codable {
    case translateGemma4B = "mlx-community/translategemma-4b-it-4bit"
    case translateGemma12B = "mlx-community/translategemma-12b-it-4bit"
    case translateGemma27B = "mlx-community/translategemma-27b-it-4bit"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .translateGemma4B:
            return "TranslateGemma 4B"
        case .translateGemma12B:
            return "TranslateGemma 12B"
        case .translateGemma27B:
            return "TranslateGemma 27B"
        }
    }

    var estimatedSize: String {
        switch self {
        case .translateGemma4B:
            return "~3 GB"
        case .translateGemma12B:
            return "~7 GB"
        case .translateGemma27B:
            return "~15 GB"
        }
    }

    var recommendedRAM: String {
        switch self {
        case .translateGemma4B:
            return "8 GB+"
        case .translateGemma12B:
            return "16 GB+"
        case .translateGemma27B:
            return "32 GB+"
        }
    }

    /// Hugging Face model ID for downloading.
    var huggingFaceId: String { rawValue }
}

// MARK: - Local LLM Model State

/// State of the local LLM model.
enum LocalLLMModelState: Equatable, Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case loading
    case ready
    case error(String)

    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }

    var isReady: Bool {
        self == .ready
    }

    var canTranslate: Bool {
        self == .ready
    }

    var statusText: String {
        switch self {
        case .notDownloaded:
            return "Not downloaded"
        case .downloading(let progress):
            return "Downloading... \(Int(progress * 100))%"
        case .downloaded:
            return "Downloaded (not loaded)"
        case .loading:
            return "Loading..."
        case .ready:
            return "Ready"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
