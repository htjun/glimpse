//
//  LocalLLMSettingsSection.swift
//  Glimpse
//

import SwiftUI

/// Settings section for Local LLM model management.
struct LocalLLMSettingsSection: View {

    // MARK: - Properties

    @State private var llmService = LocalLLMService.shared
    @State private var showingDeleteConfirmation = false
    @State private var deleteError: String?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: GlimpseTheme.Spacing.md) {
            Divider()
                .padding(.vertical, GlimpseTheme.Spacing.xs)

            // Model selection
            modelSelectionRow

            // Model status and actions
            modelStatusView

            // Error message if any
            if let error = deleteError {
                Text(error)
                    .font(GlimpseTheme.Typography.caption)
                    .foregroundStyle(.red)
            }
        }
        .alert("Delete Model?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteModel()
            }
        } message: {
            Text("This will remove the downloaded model (~\(llmService.selectedModel.estimatedSize)). You can re-download it later.")
        }
    }

    // MARK: - View Components

    private var modelSelectionRow: some View {
        HStack {
            Text("Model:")
                .font(GlimpseTheme.Typography.body)

            Picker("", selection: Binding(
                get: { llmService.selectedModel },
                set: { llmService.selectedModel = $0 }
            )) {
                ForEach(LocalLLMModel.allCases) { model in
                    HStack {
                        Text(model.displayName)
                        Text(model.estimatedSize)
                            .foregroundStyle(.secondary)
                    }
                    .tag(model)
                }
            }
            .labelsHidden()
            .disabled(llmService.modelState.isDownloading || llmService.modelState == .loading)
        }
    }

    @ViewBuilder
    private var modelStatusView: some View {
        switch llmService.modelState {
        case .notDownloaded:
            notDownloadedView

        case .downloading(let progress):
            downloadingView(progress: progress)

        case .downloaded:
            downloadedView

        case .loading:
            loadingView

        case .ready:
            readyView

        case .error(let message):
            errorView(message: message)
        }
    }

    private var notDownloadedView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Model not downloaded")
                    .font(GlimpseTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                Text("Requires \(llmService.selectedModel.recommendedRAM) RAM")
                    .font(GlimpseTheme.Typography.footnote)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button("Download") {
                Task { try? await llmService.downloadModel() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private func downloadingView(progress: Double) -> some View {
        VStack(alignment: .leading, spacing: GlimpseTheme.Spacing.xs) {
            HStack {
                Text("Downloading...")
                    .font(GlimpseTheme.Typography.caption)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(GlimpseTheme.Typography.caption)
                    .monospacedDigit()
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
        }
    }

    private var downloadedView: some View {
        HStack {
            Label("Downloaded", systemImage: "checkmark.circle.fill")
                .font(GlimpseTheme.Typography.caption)
                .foregroundStyle(.green)

            Spacer()

            Button("Load") {
                Task { try? await llmService.loadModel() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Delete") {
                showingDeleteConfirmation = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundStyle(.red)
        }
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Loading model...")
                .font(GlimpseTheme.Typography.caption)
        }
    }

    private var readyView: some View {
        HStack {
            Label("Ready", systemImage: "checkmark.circle.fill")
                .font(GlimpseTheme.Typography.caption)
                .foregroundStyle(.green)

            Spacer()

            Button("Unload") {
                llmService.unloadModel()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Delete") {
                showingDeleteConfirmation = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundStyle(.red)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: GlimpseTheme.Spacing.xs) {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .font(GlimpseTheme.Typography.caption)
                .foregroundStyle(.red)

            Text(message)
                .font(GlimpseTheme.Typography.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Button("Retry") {
                Task { try? await llmService.downloadModel() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Actions

    private func deleteModel() {
        do {
            try llmService.deleteModel()
            deleteError = nil
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

#Preview {
    Form {
        Section("Local LLM") {
            LocalLLMSettingsSection()
        }
    }
    .formStyle(.grouped)
    .frame(width: 400)
}
