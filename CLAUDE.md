# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Glimpse is a macOS background translation app (like Raycast) that:
- Runs as a menu bar app with no Dock icon (LSUIElement)
- Activates via global hotkey to show a floating translation panel
- Captures selected text from any app via accessibility APIs
- Uses Apple's built-in Translation API (macOS 15+)

## Build Commands

```bash
# Build the app
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Debug build

# Run tests
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse test

# Clean build
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse clean

# Lint (requires: brew install swiftlint)
swiftlint

# Format (requires: brew install swiftformat)
swiftformat .
```

## Architecture

### App Lifecycle
- **GlimpseApp.swift**: SwiftUI `@main` entry point with `MenuBarExtra` (menu bar icon) and floating `Window` scene
- **AppDelegate.swift**: `@Observable @MainActor` delegate handling accessibility permissions and global hotkey registration via `@NSApplicationDelegateAdaptor`

### Key Patterns
- **State Management**: Use `@Observable` macro (not ObservableObject)
- **Concurrency**: Swift 6.0 strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY = complete`)
- **Logging**: Use `os.log` Logger, never `print()`
- **Window Management**: Native SwiftUI `.windowLevel(.floating)` for the translation panel

### Project Structure
```
Glimpse/
├── App/              # Entry point, AppDelegate
├── Features/         # Feature modules (Translation/)
│   └── Translation/
│       ├── Views/
│       ├── ViewModels/
│       └── Models/
├── Core/             # Services (Accessibility, Hotkey, Translation API)
├── Shared/           # Extensions, Utilities
└── Resources/        # Assets, Info.plist, Entitlements
```

## Technical Constraints

- **macOS 15.0+ only** (required for native floating windows and Translation API)
- **Sandbox disabled** (`com.apple.security.app-sandbox = false`) - required for accessibility APIs
- **Direct distribution only** (not App Store) - accessibility access prevents sandboxing
- **Swift 6.0** with complete strict concurrency checking

## Dependencies

- **KeyboardShortcuts** (Sindre Sorhus) - Global hotkey registration via SPM
