//
//  FadingScrollbar.swift
//  Glimpse
//

import SwiftUI

/// Shared scroll metrics model for both SwiftUI and AppKit-backed editors.
struct EditorScrollMetrics: Equatable {
    let contentHeight: CGFloat
    let visibleHeight: CGFloat
    let contentOffset: CGFloat

    static let zero = EditorScrollMetrics(contentHeight: 0, visibleHeight: 0, contentOffset: 0)

    var maxOffset: CGFloat {
        max(contentHeight - visibleHeight, 0)
    }

    var clampedOffset: CGFloat {
        min(max(contentOffset, 0), maxOffset)
    }

    var needsScrollbar: Bool {
        contentHeight > visibleHeight
    }
}

/// Scrollbar renderer that only depends on scroll metrics.
struct FadingScrollbarOverlay: View {
    let metrics: EditorScrollMetrics

    @State private var isVisible = false
    @State private var hideTask: Task<Void, Never>?

    private var thumbHeight: CGFloat {
        guard metrics.contentHeight > 0 else { return 0 }
        let ratio = metrics.visibleHeight / metrics.contentHeight
        return max(GlimpseTheme.Scrollbar.minThumbHeight, metrics.visibleHeight * ratio)
    }

    private var thumbOffset: CGFloat {
        guard metrics.maxOffset > 0 else { return 0 }
        let trackHeight = metrics.visibleHeight - thumbHeight - (GlimpseTheme.Scrollbar.edgePadding * 2)
        return (metrics.clampedOffset / metrics.maxOffset) * trackHeight
    }

    var body: some View {
        Group {
            if metrics.needsScrollbar {
                ScrollbarThumb(
                    height: thumbHeight,
                    offset: thumbOffset,
                    isVisible: isVisible
                )
            }
        }
        .onChange(of: metrics) { _, newValue in
            handleMetricsChange(newValue)
        }
        .onDisappear {
            hideTask?.cancel()
            hideTask = nil
        }
    }

    private func handleMetricsChange(_ newValue: EditorScrollMetrics) {
        guard newValue.needsScrollbar else {
            hideTask?.cancel()
            hideTask = nil
            withAnimation(.easeInOut(duration: GlimpseTheme.Scrollbar.fadeOutDuration)) {
                isVisible = false
            }
            return
        }

        showScrollbar()
    }

    private func showScrollbar() {
        hideTask?.cancel()

        withAnimation(.easeInOut(duration: GlimpseTheme.Scrollbar.fadeInDuration)) {
            isVisible = true
        }

        hideTask = Task {
            try? await Task.sleep(for: .seconds(GlimpseTheme.Scrollbar.fadeDelay))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: GlimpseTheme.Scrollbar.fadeOutDuration)) {
                    isVisible = false
                }
            }
        }
    }
}

/// A view modifier that tracks SwiftUI ScrollView geometry and uses shared scrollbar rendering.
struct FadingScrollbar: ViewModifier {
    @State private var metrics = EditorScrollMetrics.zero

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: EditorScrollMetrics.self) { geometry in
                EditorScrollMetrics(
                    contentHeight: geometry.contentSize.height,
                    visibleHeight: geometry.visibleRect.height,
                    contentOffset: geometry.contentOffset.y
                )
            } action: { _, newValue in
                metrics = newValue
            }
            .overlay(alignment: .trailing) {
                FadingScrollbarOverlay(metrics: metrics)
                    .padding(.trailing, GlimpseTheme.Scrollbar.edgePadding)
                    .padding(.vertical, GlimpseTheme.Scrollbar.edgePadding)
            }
    }
}

private struct ScrollbarThumb: View {
    let height: CGFloat
    let offset: CGFloat
    let isVisible: Bool

    var body: some View {
        VStack {
            Spacer()
                .frame(height: offset)
            RoundedRectangle(cornerRadius: GlimpseTheme.Scrollbar.cornerRadius)
                .fill(GlimpseTheme.Scrollbar.thumbColor)
                .frame(width: GlimpseTheme.Scrollbar.width, height: height)
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a Raycast-style minimal fading scrollbar to a ScrollView.
    /// The scrollbar appears when scrolling and fades after 1.5 seconds of inactivity.
    func fadingScrollbar() -> some View {
        modifier(FadingScrollbar())
    }
}
