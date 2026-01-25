//
//  FadingScrollbar.swift
//  Glimpse
//

import SwiftUI

/// A view modifier that adds a Raycast-style minimal fading scrollbar overlay.
/// Uses `onScrollGeometryChange` (macOS 15+) to track scroll position.
struct FadingScrollbar: ViewModifier {

    // MARK: - State

    @State private var contentHeight: CGFloat = 0
    @State private var visibleHeight: CGFloat = 0
    @State private var contentOffset: CGFloat = 0
    @State private var isVisible: Bool = false
    @State private var hideTask: Task<Void, Never>?

    // MARK: - Computed Properties

    private var needsScrollbar: Bool {
        contentHeight > visibleHeight
    }

    private var thumbHeight: CGFloat {
        guard contentHeight > 0 else { return 0 }
        let ratio = visibleHeight / contentHeight
        return max(GlimpseTheme.Scrollbar.minThumbHeight, visibleHeight * ratio)
    }

    private var thumbOffset: CGFloat {
        let maxOffset = contentHeight - visibleHeight
        guard maxOffset > 0 else { return 0 }
        let trackHeight = visibleHeight - thumbHeight - (GlimpseTheme.Scrollbar.edgePadding * 2)
        return (contentOffset / maxOffset) * trackHeight
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollGeometryData.self) { geometry in
                ScrollGeometryData(
                    contentHeight: geometry.contentSize.height,
                    visibleHeight: geometry.visibleRect.height,
                    contentOffset: geometry.contentOffset.y
                )
            } action: { _, newValue in
                contentHeight = newValue.contentHeight
                visibleHeight = newValue.visibleHeight
                contentOffset = max(0, newValue.contentOffset)

                if needsScrollbar {
                    showScrollbar()
                }
            }
            .overlay(alignment: .trailing) {
                if needsScrollbar {
                    ScrollbarThumb(
                        height: thumbHeight,
                        offset: thumbOffset,
                        isVisible: isVisible
                    )
                    .padding(.trailing, GlimpseTheme.Scrollbar.edgePadding)
                    .padding(.vertical, GlimpseTheme.Scrollbar.edgePadding)
                }
            }
    }

    // MARK: - Private Methods

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

// MARK: - Supporting Types

private struct ScrollGeometryData: Equatable {
    let contentHeight: CGFloat
    let visibleHeight: CGFloat
    let contentOffset: CGFloat
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
