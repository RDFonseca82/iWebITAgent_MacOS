# Project generation

The original Xcode project remains available while migration is in progress.
The v2 project specification makes target membership reviewable and includes
the local `iWebITCore` package and the new macOS service sources.

On a Mac:

```bash
brew install xcodegen
xcodegen generate --spec project-v2.yml
cd iWebITMobile
xcodegen generate
```

Do not commit generated project user data. CI regenerates projects from these
specifications and builds them without code signing.

`SwiftUIIntrospect` remains temporarily on its `main` branch because the legacy
UI is coupled to its older API. Removing this dependency or pinning a compatible
release is a migration task before reproducible production releases.
