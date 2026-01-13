//
//  DictionaryService.swift
//  Glimpse
//

import Foundation
import os.log

// MARK: - Private Dictionary Services API

/// Returns a set of all available dictionaries on the system (private API).
/// Returns CFSet of DCSDictionary objects.
@_silgen_name("DCSCopyAvailableDictionaries")
private func DCSCopyAvailableDictionaries() -> CFSet?

/// Returns the name of a dictionary (private API).
/// The dictionary parameter must be a DCSDictionary from DCSCopyAvailableDictionaries.
@_silgen_name("DCSDictionaryGetName")
private func DCSDictionaryGetName(_ dictionary: AnyObject) -> CFString?

// MARK: - DictionaryService

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

    /// Cache of available bilingual dictionaries, keyed by language pattern.
    /// Stored as AnyObject since DCSDictionary is an opaque type.
    private var bilingualDictionaryCache: [String: AnyObject]?

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
        return formatDefinition(result)
    }

    /// Determines if the input text is a single word.
    /// A single word has no whitespace after trimming.
    /// - Parameter text: The text to check.
    /// - Returns: `true` if the text is a single word.
    func isSingleWord(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains(where: { $0.isWhitespace })
    }

    /// Looks up a word in a bilingual dictionary for the given language.
    /// - Parameters:
    ///   - word: The word to look up.
    ///   - languagePattern: The language pattern to find the bilingual dictionary (e.g., "Korean", "Japanese").
    /// - Returns: The bilingual definition, or `nil` if not found.
    func lookupBilingualDefinition(for word: String, languagePattern: String) -> String? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Lazily initialize the cache on first use
        if bilingualDictionaryCache == nil {
            cacheBilingualDictionaries()
        }

        guard let cache = bilingualDictionaryCache,
              let dictionary = cache[languagePattern] else {
            logger.debug("No bilingual dictionary found for pattern: \(languagePattern)")
            return nil
        }

        let nsString = trimmed as NSString
        let range = CFRangeMake(0, nsString.length)

        // Use the public DCSCopyTextDefinition API with the specific dictionary
        // Cast to DCSDictionary (the type expected by the public API)
        guard let definition = DCSCopyTextDefinition(
            unsafeBitCast(dictionary, to: DCSDictionary.self),
            nsString,
            range
        ) else {
            logger.debug("No bilingual definition found for: \(trimmed) in \(languagePattern) dictionary")
            return nil
        }

        let result = definition.takeRetainedValue() as String
        logger.debug("Found bilingual definition for: \(trimmed) in \(languagePattern) dictionary")
        return formatDefinition(result)
    }

    /// Checks if a bilingual dictionary is available for the given language pattern.
    /// - Parameter languagePattern: The language pattern to check (e.g., "Korean", "Japanese").
    /// - Returns: `true` if a bilingual dictionary is available.
    func hasBilingualDictionary(for languagePattern: String) -> Bool {
        // Lazily initialize the cache on first use
        if bilingualDictionaryCache == nil {
            cacheBilingualDictionaries()
        }
        return bilingualDictionaryCache?[languagePattern] != nil
    }

    // MARK: - Private Methods

    /// Parts of speech patterns for each language.
    /// Add new languages here - no code changes needed in formatDefinition().
    private let partsOfSpeechByLanguage: [String: [String]] = [
        "Korean": ["명사", "형용사", "동사", "부사", "감탄사"],
        "English": ["noun", "verb", "adjective", "adverb", "interjection"],
        "Japanese": ["名詞", "動詞", "形容詞", "副詞", "感動詞"],
        "Chinese": ["名词", "动词", "形容词", "副词", "叹词"],
        "Spanish": ["sustantivo", "verbo", "adjetivo", "adverbio"],
        "French": ["nom", "verbe", "adjectif", "adverbe"],
        "German": ["Substantiv", "Verb", "Adjektiv", "Adverb"],
    ]

    /// Formats a raw dictionary definition string for better readability.
    /// Adds line breaks after pronunciation, etymology, before numbered definitions, and examples.
    private func formatDefinition(_ raw: String) -> String {
        var result = raw

        // Universal patterns (apply to all dictionaries)

        // 1. Newline after pronunciation (| ... |)
        result = result.replacingOccurrences(
            of: #"(\|[^|]+\|)(\s+)"#,
            with: "$1\n",
            options: .regularExpression
        )

        // 2. Newline after etymology【...】
        result = result.replacingOccurrences(
            of: #"(【[^】]+】)\s*"#,
            with: "$1\n\n",
            options: .regularExpression
        )

        // 3. Newline before numbered definitions (1., 2., etc.)
        //    But not for sub-numbers like "1.1"
        result = result.replacingOccurrences(
            of: #"(?<=[^\d\n])\s*(\d+\.(?!\d))"#,
            with: "\n$1",
            options: .regularExpression
        )

        // 4. Newline + indent before examples (▸)
        result = result.replacingOccurrences(
            of: #"\s*(▸)"#,
            with: "\n   $1",
            options: .regularExpression
        )

        // Language-specific: parts of speech from all languages
        let allPartsOfSpeech = partsOfSpeechByLanguage.values.flatMap { $0 }
        let posPattern = allPartsOfSpeech.joined(separator: "|")
        result = result.replacingOccurrences(
            of: "(?<=\\.)\\s*(\(posPattern))\\b",
            with: "\n\n$1",
            options: [.regularExpression, .caseInsensitive]
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Caches available bilingual dictionaries.
    private func cacheBilingualDictionaries() {
        var cache: [String: AnyObject] = [:]

        guard let dictionarySet = DCSCopyAvailableDictionaries() else {
            logger.warning("Could not retrieve available dictionaries")
            bilingualDictionaryCache = cache
            return
        }

        // Convert CFSet to NSSet to iterate
        let nsSet = dictionarySet as NSSet

        logger.info("Found \(nsSet.count) dictionaries on system")

        // Dictionary name patterns for bilingual dictionaries
        // Maps our language key to patterns that identify the dictionary
        let bilingualDictionaries: [String: [String]] = [
            "Korean": ["영한", "한영"],  // Korean-English patterns
            "Japanese": ["ウィズダム英和", "ウィズダム和英", "WISDOM"],  // Japanese-English
            "Simplified Chinese": ["牛津英汉汉英"],  // Oxford English-Chinese
            "Traditional Chinese": ["譯典通英漢"],  // Traditional Chinese-English
            "French": ["Oxford-Hachette French"],
            "German": ["Oxford German Dictionary"],
            "Spanish": ["Gran Diccionario Oxford"],
            "Italian": ["Oxford Paravia"],
            "Portuguese": ["Oxford Portuguese Dictionary"],
            "Hindi": ["Oxford Hindi Dictionaries"],
            "Thai": ["พจนานุกรมอังกฤษ-ไทย"],  // English-Thai dictionary
            "Vietnamese": ["Từ điển Lạc Việt"],
        ]

        for dictionary in nsSet {
            let dictObj = dictionary as AnyObject
            guard let nameRef = DCSDictionaryGetName(dictObj),
                  let name = nameRef as String? else {
                continue
            }

            logger.debug("Available dictionary: \(name)")

            // Find which language pattern this dictionary matches
            for (languageKey, patterns) in bilingualDictionaries where cache[languageKey] == nil {
                if patterns.contains(where: { name.contains($0) }) {
                    cache[languageKey] = dictObj
                    logger.info("Cached bilingual dictionary: \(name) for pattern: \(languageKey)")
                }
            }
        }

        bilingualDictionaryCache = cache
        logger.info("Bilingual dictionary cache initialized with \(cache.count) dictionaries")
    }
}
