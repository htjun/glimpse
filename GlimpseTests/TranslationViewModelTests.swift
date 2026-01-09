//
//  TranslationViewModelTests.swift
//  GlimpseTests
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import Testing
@testable import Glimpse

@MainActor
struct TranslationViewModelTests {

    // MARK: - consumeCapturedText Tests

    @Test func consumeCapturedTextReturnsAndClearsText() async throws {
        let viewModel = TranslationViewModel.shared

        // Set up captured text
        viewModel.capturedText = "Hello, world!"

        // First consumption should return the text
        let result = viewModel.consumeCapturedText()
        #expect(result == "Hello, world!")

        // Text should be cleared
        #expect(viewModel.capturedText == nil)
    }

    @Test func consumeCapturedTextReturnsNilWhenEmpty() async throws {
        let viewModel = TranslationViewModel.shared

        // Ensure no captured text
        viewModel.capturedText = nil

        // Should return nil
        let result = viewModel.consumeCapturedText()
        #expect(result == nil)
    }

    @Test func multipleConsumptionsReturnNilAfterFirst() async throws {
        let viewModel = TranslationViewModel.shared

        // Set up captured text
        viewModel.capturedText = "Test text"

        // First consumption returns text
        let first = viewModel.consumeCapturedText()
        #expect(first == "Test text")

        // Second consumption returns nil
        let second = viewModel.consumeCapturedText()
        #expect(second == nil)

        // Third consumption also returns nil
        let third = viewModel.consumeCapturedText()
        #expect(third == nil)
    }

    @Test func capturedTextPropertyCanBeSetAndRead() async throws {
        let viewModel = TranslationViewModel.shared

        // Set text
        viewModel.capturedText = "Some captured text"
        #expect(viewModel.capturedText == "Some captured text")

        // Update text
        viewModel.capturedText = "Updated text"
        #expect(viewModel.capturedText == "Updated text")

        // Clear text
        viewModel.capturedText = nil
        #expect(viewModel.capturedText == nil)
    }

    @Test func consumeCapturedTextHandlesEmptyString() async throws {
        let viewModel = TranslationViewModel.shared

        // Set empty string (not nil)
        viewModel.capturedText = ""

        // Should return empty string, not nil
        let result = viewModel.consumeCapturedText()
        #expect(result == "")

        // Should be cleared after consumption
        #expect(viewModel.capturedText == nil)
    }

    // MARK: - prepareForNewCapture Tests

    @Test func prepareForNewCaptureClearsTextAndSetsCapturing() async throws {
        let viewModel = TranslationViewModel.shared

        // Set up existing state
        viewModel.capturedText = "Previous text"
        viewModel.isCapturingText = false

        // Prepare for new capture
        viewModel.prepareForNewCapture()

        // Should clear text and set capturing flag
        #expect(viewModel.capturedText == nil)
        #expect(viewModel.isCapturingText == true)
    }

    @Test func finishCaptureClearsCapturingFlag() async throws {
        let viewModel = TranslationViewModel.shared

        // Set capturing state
        viewModel.isCapturingText = true

        // Finish capture
        viewModel.finishCapture()

        // Should clear capturing flag
        #expect(viewModel.isCapturingText == false)
    }

    @Test func captureLifecycleWorksCorrectly() async throws {
        let viewModel = TranslationViewModel.shared

        // Initial state
        viewModel.capturedText = "Old text"
        viewModel.isCapturingText = false

        // Start capture
        viewModel.prepareForNewCapture()
        #expect(viewModel.isCapturingText == true)
        #expect(viewModel.capturedText == nil)

        // Simulate text capture
        viewModel.capturedText = "New captured text"

        // Finish capture
        viewModel.finishCapture()
        #expect(viewModel.isCapturingText == false)
        #expect(viewModel.capturedText == "New captured text")
    }
}
