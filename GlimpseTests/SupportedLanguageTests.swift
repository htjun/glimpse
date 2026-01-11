//
//  SupportedLanguageTests.swift
//  GlimpseTests
//

import Testing
@testable import Glimpse

/// Tests that language display names and identifiers are correct.
/// Users depend on seeing correct language names in settings,
/// and the Translation API requires valid BCP 47 identifiers.
@Suite
struct SupportedLanguageTests {

    @Test
    func allLanguagesHaveUniqueDisplayNames() {
        let displayNames = SupportedLanguage.allCases.map(\.displayName)
        let uniqueNames = Set(displayNames)
        #expect(displayNames.count == uniqueNames.count, "Display names must be unique")
    }

    @Test
    func allLanguagesHaveUniqueIdentifiers() {
        let identifiers = SupportedLanguage.allCases.map(\.rawValue)
        let uniqueIds = Set(identifiers)
        #expect(identifiers.count == uniqueIds.count, "BCP 47 identifiers must be unique")
    }

    @Test
    func displayNameIsNotEmpty() {
        for language in SupportedLanguage.allCases {
            #expect(!language.displayName.isEmpty, "\(language) display name should not be empty")
        }
    }

    @Test
    func chineseVariantsAreDistinguishable() {
        let simplified = SupportedLanguage.chineseSimplified
        let traditional = SupportedLanguage.chineseTraditional

        #expect(simplified.displayName != traditional.displayName)
        #expect(simplified.rawValue != traditional.rawValue)
        #expect(simplified.displayName.contains("Simplified"))
        #expect(traditional.displayName.contains("Traditional"))
    }

    @Test
    func idMatchesRawValue() {
        for language in SupportedLanguage.allCases {
            #expect(language.id == language.rawValue)
        }
    }

    @Test
    func localeLanguageUsesRawValue() {
        for language in SupportedLanguage.allCases {
            let locale = language.localeLanguage
            #expect(locale.languageCode?.identifier == language.rawValue.components(separatedBy: "-").first)
        }
    }
}
