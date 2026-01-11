//
//  LanguageSettings.swift
//  Glimpse
//

import Foundation
import Translation

/// Supported languages for translation.
/// Raw values are BCP 47 language identifiers compatible with Apple's Translation API.
enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case korean = "ko"
    case japanese = "ja"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case arabic = "ar"
    case hindi = "hi"
    case thai = "th"
    case vietnamese = "vi"
    case indonesian = "id"

    var id: String { rawValue }

    /// Human-readable display name for the language.
    var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "Korean"
        case .japanese: return "Japanese"
        case .chineseSimplified: return "Chinese (Simplified)"
        case .chineseTraditional: return "Chinese (Traditional)"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .russian: return "Russian"
        case .arabic: return "Arabic"
        case .hindi: return "Hindi"
        case .thai: return "Thai"
        case .vietnamese: return "Vietnamese"
        case .indonesian: return "Indonesian"
        }
    }

    /// Short display name for the language (3 letters).
    var shortName: String {
        switch self {
        case .english: return "Eng"
        case .korean: return "Kor"
        case .japanese: return "Jpn"
        case .chineseSimplified: return "Chn"
        case .chineseTraditional: return "Cht"
        case .spanish: return "Esp"
        case .french: return "Fra"
        case .german: return "Deu"
        case .italian: return "Ita"
        case .portuguese: return "Por"
        case .russian: return "Rus"
        case .arabic: return "Ara"
        case .hindi: return "Hin"
        case .thai: return "Tha"
        case .vietnamese: return "Vie"
        case .indonesian: return "Ind"
        }
    }

    /// Converts to `Locale.Language` for the Translation API.
    var localeLanguage: Locale.Language {
        Locale.Language(identifier: rawValue)
    }
}

/// Keys for UserDefaults storage.
enum LanguageSettingsKey {
    static let languageOne = "languageOne"
    static let languageTwo = "languageTwo"
}
