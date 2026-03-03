//
//  SourceTextEditor.swift
//  Glimpse
//

import AppKit
import SwiftUI

/// Native AppKit-backed source editor so caret/text/placeholder share one text layout engine.
struct SourceTextEditor: NSViewRepresentable {

    // MARK: - Properties

    @Binding var text: String
    @Binding var scrollMetrics: EditorScrollMetrics
    let placeholder: String
    let autoFocus: Bool

    // MARK: - NSViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlaceholderTextView(frame: .zero)
        configureTextViewBehavior(textView)
        applyEditorStyle(to: textView)

        let scrollView = NSScrollView(frame: .zero)
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.documentView = textView

        context.coordinator.attach(scrollView: scrollView, textView: textView)
        context.coordinator.syncTextFromBinding()
        context.coordinator.refreshMetrics()
        context.coordinator.applyFocusIfNeeded()

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = nsView.documentView as? PlaceholderTextView else { return }
        applyEditorStyle(to: textView)
        context.coordinator.syncTextFromBinding()
        context.coordinator.refreshMetrics()
        context.coordinator.applyFocusIfNeeded()
    }

    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        coordinator.detach()
    }

    // MARK: - Private Methods

    private func configureTextViewBehavior(_ textView: PlaceholderTextView) {
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.autoresizingMask = [.width]

        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
    }

    private func applyEditorStyle(to textView: PlaceholderTextView) {
        let bodyFont = NSFont(
            name: "Geist-Regular",
            size: GlimpseTheme.Typography.bodyPointSize
        ) ?? .systemFont(ofSize: GlimpseTheme.Typography.bodyPointSize)

        textView.font = bodyFont
        textView.textColor = NSColor(GlimpseTheme.Colors.textPrimary)
        textView.insertionPointColor = NSColor(GlimpseTheme.Colors.textPrimary)
        textView.placeholderString = placeholder
        textView.placeholderColor = NSColor(GlimpseTheme.Colors.placeholderText)
        textView.textContainerInset = NSSize(
            width: GlimpseTheme.Editor.textContainerInsetHorizontal,
            height: GlimpseTheme.Editor.textContainerInsetVertical
        )
        textView.textContainer?.lineFragmentPadding = GlimpseTheme.Editor.lineFragmentPadding
        textView.needsDisplay = true
    }
}

// MARK: - Coordinator

extension SourceTextEditor {

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SourceTextEditor

        private weak var scrollView: NSScrollView?
        private weak var textView: PlaceholderTextView?

        private var isSyncingFromSwiftUI = false
        private var hasAppliedInitialFocus = false

        init(parent: SourceTextEditor) {
            self.parent = parent
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func attach(scrollView: NSScrollView, textView: PlaceholderTextView) {
            self.scrollView = scrollView
            self.textView = textView

            textView.delegate = self

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(clipViewBoundsDidChange(_:)),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        }

        func detach() {
            NotificationCenter.default.removeObserver(self)
        }

        func syncTextFromBinding() {
            guard let textView, textView.string != parent.text else { return }
            isSyncingFromSwiftUI = true
            textView.string = parent.text
            isSyncingFromSwiftUI = false
            textView.needsDisplay = true
        }

        func applyFocusIfNeeded() {
            guard parent.autoFocus, !hasAppliedInitialFocus, let textView else { return }

            DispatchQueue.main.async { [weak self, weak textView] in
                guard let self, let textView else { return }
                textView.window?.makeFirstResponder(textView)
                self.hasAppliedInitialFocus = true
            }
        }

        func refreshMetrics() {
            guard let scrollView else { return }

            let visibleHeight = scrollView.contentView.bounds.height
            let contentHeight = max(
                scrollView.documentView?.bounds.height ?? 0,
                visibleHeight
            )
            let contentOffset = scrollView.contentView.bounds.origin.y

            let metrics = EditorScrollMetrics(
                contentHeight: contentHeight,
                visibleHeight: visibleHeight,
                contentOffset: contentOffset
            )

            if parent.scrollMetrics != metrics {
                parent.scrollMetrics = metrics
            }
        }

        // MARK: NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }

            textView.needsDisplay = true

            if !isSyncingFromSwiftUI, parent.text != textView.string {
                parent.text = textView.string
            }

            refreshMetrics()
        }

        @objc
        private func clipViewBoundsDidChange(_ notification: Notification) {
            refreshMetrics()
        }
    }
}

// MARK: - Placeholder Text View

@MainActor
final class PlaceholderTextView: NSTextView {
    var placeholderString = "" {
        didSet { needsDisplay = true }
    }

    var placeholderColor: NSColor = .placeholderTextColor {
        didSet { needsDisplay = true }
    }

    override func didChangeText() {
        super.didChangeText()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard string.isEmpty, !placeholderString.isEmpty else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? .systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: placeholderColor
        ]

        let point = NSPoint(
            x: textContainerOrigin.x + (textContainer?.lineFragmentPadding ?? 0),
            y: textContainerOrigin.y
        )

        (placeholderString as NSString).draw(at: point, withAttributes: attributes)
    }
}
