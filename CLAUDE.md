# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Glimpse is a macOS background translation app (like Raycast) that:
- Runs as a menu bar app with no Dock icon (LSUIElement)
- Activates via global hotkey to show a floating translation panel
- Captures selected text from any app via accessibility APIs
- Uses Apple's built-in Translation API (macOS 15.5+)
- Provides dictionary definitions for single words via macOS Dictionary APIs

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
- **GlimpseApp.swift**: SwiftUI `@main` entry point with `MenuBarExtra` (menu bar icon) and `Settings` scene
- **AppDelegate.swift**: `@Observable @MainActor` delegate handling accessibility permissions and global hotkey registration via `@NSApplicationDelegateAdaptor`
- **WindowManager**: Manages the translation panel lifecycle (the panel is an `NSPanel`, not a SwiftUI Window scene)

### Key Patterns
- **State Management**: Use `@Observable` macro (not ObservableObject)
- **Concurrency**: Swift 6.0 strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY = complete`)
- **Logging**: Use `os.log` Logger, never `print()`
- **Window Management**: Hybrid AppKit/SwiftUI - custom `TranslationPanel` (NSPanel subclass) managed by `WindowManager` singleton

### Project Structure
```
Glimpse/
├── App/                    # Entry point, AppDelegate
├── Features/
│   ├── Translation/        # Translation panel
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   └── Settings/           # Settings window
│       └── Views/
├── Core/
│   ├── Hotkey/             # KeyboardShortcuts extension
│   └── Services/           # AccessibilityService, WindowManager, TranslationPanel, DictionaryService
├── Shared/
│   ├── Components/         # Reusable button styles
│   ├── DesignSystem/       # Theme, colors, typography (GlimpseTheme)
│   ├── Extensions/
│   └── Utilities/
└── Resources/              # Assets, Fonts, Info.plist, Entitlements
```

## Technical Constraints

- **macOS 15.5+ only** (required for Translation API and NaturalLanguage features)
- **Sandbox disabled** (`com.apple.security.app-sandbox = false`) - required for accessibility APIs
- **Direct distribution only** (not App Store) - accessibility access prevents sandboxing
- **Swift 6.0** with complete strict concurrency checking

## Core Services

- **AccessibilityService**: Captures selected text by simulating Cmd+C and reading clipboard (preserves original clipboard contents)
- **WindowManager**: Manages translation panel state (open/close), positioning, and click-outside-to-close via global mouse monitoring
- **TranslationPanel**: Custom borderless `NSPanel` subclass for the floating translation window
- **DictionaryService**: Accesses macOS Dictionary APIs for word definitions and bilingual dictionary lookups

## Dependencies

- **KeyboardShortcuts** (Sindre Sorhus) - Global hotkey registration via SPM

## Testing Notes

- **UI tests require the app to not be running**: UI tests will fail/timeout if Glimpse is already running (e.g., launched from Xcode). The tests terminate any existing instance before launching, but if the app is stuck or unresponsive, manually quit it before running tests.
- **Accessibility prompt is skipped in tests**: The app detects `XCTestConfigurationFilePath` environment variable to skip the accessibility permission dialog during UI tests.
