# Agent versioning

The Apple 2.0 release line uses:

- marketing version: `2.0.0`;
- build number: `211`;
- synchronization schema: `2.0`.

`Configuration/version.json` is the human-readable source of truth. The
macOS app, menu-bar agent, privileged daemon, iPhone/iPad app, legacy package
builder, XcodeGen projects and GitHub release defaults must all match it.

At runtime, Apple agents read `CFBundleShortVersionString` and
`CFBundleVersion` from their signed binary. The constants `2.0.0` and `211`
are only fallbacks for a command-line build without embedded bundle metadata.

Run this before a release:

```bash
python3 scripts/ci/check_version_consistency.py
```

For a future release, update `Configuration/version.json` and every location
reported by the checker. Build numbers must increase monotonically; never
reuse an App Store build number for different signed binaries.
