# Contributing

Thanks for contributing to Glimpse.

## Prerequisites

- macOS 15.5 or newer
- Xcode 16.4 or newer
- Accessibility access enabled for the built app when testing capture flows
- Apple Silicon is strongly recommended if you plan to use the local TranslateGemma backend

## Local setup

1. Clone the repository.
2. Open [Glimpse.xcodeproj](Glimpse.xcodeproj) in Xcode.
3. If you want to run the app locally, select your own signing team for the `Glimpse` target.
4. Build and run the `Glimpse` scheme.

## Development expectations

- Keep changes focused and documented.
- Add or update tests when behavior changes.
- Update [README.md](README.md) when public setup or user-facing behavior changes.
- Do not commit secrets, private certificates, or local Xcode user data.

## Useful commands

```bash
# Resolve dependencies and build without code signing
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build

# Run tests
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test

# Lint and format
swiftlint
swiftformat .
```

## Pull requests

- Describe the behavior change and how you verified it.
- Call out any macOS, accessibility, or local-LLM specific caveats.
- Keep generated artifacts and personal IDE settings out of the diff.
