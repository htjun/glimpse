# Glimpse

A lightweight macOS menu bar app for instant translation of selected text.

![macOS 15.5+](https://img.shields.io/badge/macOS-15.5%2B-blue)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)

## Overview

Glimpse stays in the menu bar and opens with a global shortcut. Select text in any app, press the shortcut, and Glimpse captures the selection, shows a floating panel, and translates without forcing an app switch.

## Features

- Menu bar app with no Dock icon
- Global hotkey: `Cmd+Shift+Space`
- Accessibility-based selected text capture
- Floating translation panel with dictionary fallback for single words
- Apple Translation backend for native translation on macOS 15.5+
- Optional local TranslateGemma backend with offline translations after the initial model download

## Requirements

- macOS 15.5 or later
- Xcode 16.4 or later for development
- Accessibility permission for text capture
- Apple Silicon recommended for the local TranslateGemma backend

> Glimpse requires accessibility access and runs outside the App Store sandbox. Expect direct distribution or local builds instead of App Store deployment.

## Build From Source

1. Clone the repository:

   ```bash
   git clone https://github.com/htjun/Glimpse.git
   cd Glimpse
   ```

2. Open [Glimpse.xcodeproj](Glimpse.xcodeproj) in Xcode.
3. Select a personal signing team for the `Glimpse` target if you want to run the app locally.
4. Build and run the shared `Glimpse` scheme.

### Command-line build and test

These commands avoid code signing, which is useful for CI and local verification:

```bash
# Build
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build

# Test
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
```

## Accessibility Setup

On first launch, Glimpse asks for accessibility access so it can read selected text from other applications.

1. Open **System Settings -> Privacy & Security -> Accessibility**
2. Enable **Glimpse**
3. Restart the app if macOS does not grant access immediately

## Translation Backends

### Apple Translation

- Built into macOS 15.5+
- No extra setup beyond app permissions
- Best default path for most contributors and users

### TranslateGemma (Local)

Glimpse can run translations through a local MLX-backed TranslateGemma model.

- Available models:
  - `TranslateGemma 4B` (`~3 GB`, recommended `8 GB+` RAM)
  - `TranslateGemma 12B` (`~7 GB`, recommended `16 GB+` RAM)
  - `TranslateGemma 27B` (`~15 GB`, recommended `32 GB+` RAM)
- Models are downloaded on demand from Hugging Face the first time you request them.
- After download, translations can run fully offline.
- The local backend is exposed in Settings and loads automatically on launch if a model is already present.

Before downloading model weights, review the upstream model card and license terms that apply to your use.

## Development

### Code quality

```bash
swiftlint
swiftformat .
```

### Project structure

```text
Glimpse/
├── App/                 # App entry point and lifecycle
├── Core/                # Accessibility, panel, window, and translation services
├── Features/            # Translation and settings UI
├── Resources/           # Assets, fonts, entitlements, and Info.plist
└── Shared/              # Reusable components and design system
```

## Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) for global hotkeys
- Vendored [mlx-swift-lm](https://github.com/ml-explore/mlx-swift-lm) packages for local TranslateGemma support

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for bundled asset and dependency notes.
