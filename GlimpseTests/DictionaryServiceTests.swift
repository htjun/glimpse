//
//  DictionaryServiceTests.swift
//  GlimpseTests
//

import Testing
@testable import Glimpse

@MainActor
struct DictionaryServiceTests {

    // MARK: - isSingleWord Tests

    @Test func isSingleWordReturnsTrueForSimpleWord() {
        let service = DictionaryService.shared
        #expect(service.isSingleWord("hello") == true)
        #expect(service.isSingleWord("world") == true)
    }

    @Test func isSingleWordReturnsFalseForMultipleWords() {
        let service = DictionaryService.shared
        #expect(service.isSingleWord("hello world") == false)
        #expect(service.isSingleWord("one two three") == false)
    }

    @Test func isSingleWordHandlesWhitespace() {
        let service = DictionaryService.shared
        #expect(service.isSingleWord("  hello  ") == true)
        #expect(service.isSingleWord("hello\tworld") == false)
        #expect(service.isSingleWord("hello\nworld") == false)
    }

    @Test func isSingleWordReturnsFalseForEmpty() {
        let service = DictionaryService.shared
        #expect(service.isSingleWord("") == false)
        #expect(service.isSingleWord("   ") == false)
    }

    @Test func isSingleWordHandlesNonLatinCharacters() {
        let service = DictionaryService.shared
        #expect(service.isSingleWord("bonjour") == true)
        #expect(service.isSingleWord("hola mundo") == false)
    }

    // MARK: - lookupDefinition Tests

    @Test func lookupDefinitionReturnsNilForEmptyString() {
        let service = DictionaryService.shared
        #expect(service.lookupDefinition(for: "") == nil)
        #expect(service.lookupDefinition(for: "   ") == nil)
    }

    @Test func lookupDefinitionReturnsNilForNonsense() {
        let service = DictionaryService.shared
        #expect(service.lookupDefinition(for: "xyzzyplugh123") == nil)
    }

    @Test func lookupDefinitionReturnsValueForKnownWord() {
        let service = DictionaryService.shared
        let result = service.lookupDefinition(for: "hello")
        #expect(result != nil)
        #expect(result?.isEmpty == false)
    }
}
