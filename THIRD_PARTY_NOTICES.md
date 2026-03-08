# Third-Party Notices

Glimpse includes or depends on third-party software and assets. This file summarizes the notable components used by the repository and app.

## Included in this repository

### `LocalPackages/mlx-swift-lm`

- Source: `https://github.com/ml-explore/mlx-swift-lm`
- Copyright: `ml-explore`
- License: MIT
- Notes: The vendored copy in this repository keeps the upstream `LICENSE`, `ACKNOWLEDGMENTS.md`, `CODE_OF_CONDUCT.md`, and `CONTRIBUTING.md` files.

### `Glimpse/Resources/Fonts/Geist-*.otf`

- Source: `https://github.com/vercel/geist-font`
- Copyright: `Copyright 2024 The Geist Project Authors`
- License: SIL Open Font License 1.1
- Notes: The copyright string is embedded in the included font binaries.

## Pulled in by Swift Package Manager

### `KeyboardShortcuts`

- Source: `https://github.com/sindresorhus/KeyboardShortcuts`
- Copyright: Sindre Sorhus
- License: MIT
- Usage: Global hotkey registration for the menu bar app.

### Transitive packages resolved by `Package.resolved`

- `mlx-swift` by `ml-explore`
- `swift-collections` by Apple
- `swift-jinja` by Hugging Face
- `swift-numerics` by Apple
- `swift-transformers` by Hugging Face

These dependencies are resolved and pinned through [Glimpse.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved](Glimpse.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved). Refer to each upstream repository for the latest license text and notices.

## Runtime-downloaded model weights

Glimpse can download TranslateGemma model weights at runtime from Hugging Face:

- `mlx-community/translategemma-4b-it-4bit`
- `mlx-community/translategemma-12b-it-4bit`
- `mlx-community/translategemma-27b-it-4bit`

These model weights are not redistributed in this repository. Before downloading them, review the upstream model cards, licenses, and any provider terms that apply to your intended use.
