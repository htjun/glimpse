//
//  DictionaryService.swift
//  Glimpse
//

import Foundation
import os.log

/// Service for looking up word definitions using macOS Dictionary.
@MainActor
final class DictionaryService {

    // MARK: - Singleton

    static let shared = DictionaryService()

    // MARK: - Properties

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Glimpse",
        category: "DictionaryService"
    )

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Looks up the definition for a word in the macOS Dictionary.
    /// - Parameter word: The word to look up (should be a single word).
    /// - Returns: The definition string, or `nil` if no definition was found.
    func lookupDefinition(for word: String) -> String? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let nsString = trimmed as NSString
        let range = CFRangeMake(0, nsString.length)

        guard let definition = DCSCopyTextDefinition(nil, nsString, range) else {
            logger.debug("No definition found for: \(trimmed)")
            return nil
        }

        let result = definition.takeRetainedValue() as String
        logger.debug("Found definition for: \(trimmed)")
        return result
    }

    /// Determines if the input text is a single word.
    /// A single word has no whitespace after trimming.
    /// - Parameter text: The text to check.
    /// - Returns: `true` if the text is a single word.
    func isSingleWord(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains(where: { $0.isWhitespace })
    }
}
