//
//  TranslationEngineSettingsView.swift
//  Glimpse
//

import SwiftUI

/// Settings view for selecting translation engine.
struct TranslationEngineSettingsView: View {

    // MARK: - Properties

    @Binding var selectedBackend: TranslationBackendType

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: GlimpseTheme.Spacing.md) {
            // Backend selection
            Picker("Engine:", selection: $selectedBackend) {
                ForEach(TranslationBackendType.allCases) { backend in
                    Text(backend.displayName).tag(backend)
                }
            }
            .pickerStyle(.segmented)

            // Description
            Text(selectedBackend.description)
                .font(GlimpseTheme.Typography.caption)
                .foregroundStyle(.secondary)

            // Local LLM specific settings
            if selectedBackend == .localLLM {
                LocalLLMSettingsSection()
            }
        }
    }
}

#Preview {
    @Previewable @State var backend: TranslationBackendType = .apple
    return Form {
        Section("Translation Engine") {
            TranslationEngineSettingsView(selectedBackend: $backend)
        }
    }
    .formStyle(.grouped)
    .frame(width: 400)
}
