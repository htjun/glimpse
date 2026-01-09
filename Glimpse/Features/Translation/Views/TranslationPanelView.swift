//
//  TranslationPanelView.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit
import SwiftUI

/// Main translation panel view - floating window activated by hotkey.
struct TranslationPanelView: View {

    // MARK: - Properties

    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Input text field
            TextField("Enter text to translate...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .lineLimit(1...5)
                .focused($isInputFocused)
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onSubmit {
                    translateText()
                }

            // Translation result
            if !translatedText.isEmpty || isTranslating {
                Divider()

                if isTranslating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(maxWidth: .infinity, minHeight: 40)
                } else {
                    Text(translatedText)
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Action buttons
            HStack {
                // Hidden escape button to capture Escape key
                Button("") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .hidden()

                Spacer()

                Button("Translate") {
                    translateText()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(inputText.isEmpty || isTranslating)
            }
        }
        .padding(20)
        .frame(width: 480, alignment: .top)
        .background(.ultraThinMaterial)
        .background(WindowAccessor())
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Private Methods

    private func translateText() {
        guard !inputText.isEmpty else { return }

        isTranslating = true

        // TODO: Implement actual translation using Apple Translation API
        // For now, simulate a translation delay
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                translatedText = "Translation of: \"\(inputText)\""
                isTranslating = false
            }
        }
    }
}

#Preview {
    TranslationPanelView()
}

// MARK: - Window Accessor

/// Custom NSView that captures window reference when added to hierarchy.
private class WindowCaptureView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            WindowManager.shared.registerPanelWindow(window)
        }
    }
}

/// Captures the NSWindow reference and registers it with WindowManager.
private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowCaptureView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
