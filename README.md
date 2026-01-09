# Glimpse

A lightweight macOS menu bar app for instant translation of selected text.

![macOS 15.0+](https://img.shields.io/badge/macOS-15.0%2B-blue)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)

## Overview

Glimpse runs quietly in your menu bar and activates instantly with a global hotkey. Select text in any application, press the hotkey, and get a translation in a floating panel—no context switching required.

## Features

- **Menu Bar App** — Runs in the background with no Dock icon
- **Global Hotkey** — Activate from anywhere with `Cmd+Shift+Space`
- **Automatic Text Capture** — Grabs selected text from any application via accessibility APIs
- **Floating Panel** — Translation appears in a non-intrusive floating window
- **Native Translation** — Uses Apple's built-in Translation API for fast, private translations

## Requirements

- macOS 15.0 or later
- Accessibility permissions (required for text capture)

> **Note:** Glimpse requires accessibility access and cannot be sandboxed, so it's distributed directly rather than through the App Store.

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Glimpse.git
   cd Glimpse
   ```

2. Open in Xcode:
   ```bash
   open Glimpse.xcodeproj
   ```

3. Build and run (`Cmd+R`)

### Granting Accessibility Permissions

On first launch, Glimpse will request accessibility permissions:

1. Go to **System Settings → Privacy & Security → Accessibility**
2. Enable **Glimpse** in the list
3. Restart Glimpse if needed

## Usage

1. **Activate**: Press `Cmd+Shift+Space` (or click the menu bar icon)
2. **Translate**: Selected text is automatically captured and ready for translation
3. **Shortcuts**:
   - `Cmd+Return` — Translate
   - `Escape` — Close panel

## Development

### Build Commands

```bash
# Build
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Debug build

# Run tests
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse test

# Clean
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse clean
```

### Code Quality

```bash
# Lint (requires: brew install swiftlint)
swiftlint

# Format (requires: brew install swiftformat)
swiftformat .
```

### Project Structure

```
Glimpse/
├── App/              # Entry point, AppDelegate
├── Features/         # Feature modules
│   └── Translation/  # Translation panel views and view models
├── Core/             # Services (Accessibility, Hotkey, Window management)
├── Shared/           # Extensions and utilities
└── Resources/        # Assets, Info.plist, Entitlements
```

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus — Global hotkey registration
