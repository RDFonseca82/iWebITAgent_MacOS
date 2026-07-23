# GitHub Apple release and update delivery

`.github/workflows/apple-release.yml` is a manually approved release workflow.
It serializes releases through the protected `apple-release` environment and:

1. validates version/build, JSON, shell scripts, core security and backend contract tests;
2. builds all macOS 2.0 targets on a GitHub-hosted macOS runner;
3. embeds the trusted update public key and GitHub channel URL in the pkg;
4. signs applications and daemon with Developer ID Application;
5. signs the pkg with Developer ID Installer, notarizes it and staples the ticket;
6. creates an Ed25519-signed manifest and SHA-256 file;
7. builds and signs the universal iPhone/iPad IPA;
8. optionally uploads the IPA to App Store Connect/TestFlight;
9. publishes the macOS pkg, manifest and checksums in an immutable GitHub Release.

The release tag is `v<version>-<build>`. Publication waits for both Apple builds
to succeed and refuses to overwrite an existing tag. GitHub Actions artifacts
are also retained for controlled download and diagnostics.

## Distribution boundaries

The macOS agent can update directly from the latest public GitHub Release
because the downloaded manifest and pkg are independently verified. A private
GitHub repository cannot be used as an unauthenticated device download channel;
use the authenticated backend or an HTTPS CDN for that case, without embedding
a repository token in the agent.

iPhone and iPad cannot self-update from GitHub. GitHub builds and uploads the
signed IPA; TestFlight or the App Store performs installation and updates. Set
`upload_to_testflight: true` when starting the workflow to enable the upload.

## Required GitHub Actions secrets

macOS signing and notarization:

- `APPLE_TEAM_ID`
- `DEVELOPER_ID_APPLICATION_IDENTITY`
- `DEVELOPER_ID_INSTALLER_IDENTITY`
- `DEVELOPER_ID_APPLICATION_P12_BASE64`
- `DEVELOPER_ID_INSTALLER_P12_BASE64`
- `DEVELOPER_ID_P12_PASSWORD`
- `NOTARY_KEY_ID`
- `NOTARY_ISSUER_ID`
- `NOTARY_PRIVATE_KEY_BASE64`

Universal iOS/iPadOS signing:

- `IOS_DISTRIBUTION_P12_BASE64`
- `IOS_DISTRIBUTION_P12_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`

App Store Connect/TestFlight, required only when upload is enabled:

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY_BASE64`

Use an App Store Connect team API key with an appropriate Developer/App Manager
role. The application record and bundle identifier must already exist in App
Store Connect.

Release security:

- `IWEBIT_UPDATE_PRIVATE_KEY_BASE64`: raw 32-byte Ed25519 private key encoded
  as Base64;
- `IWEBIT_UPDATE_PUBLIC_KEY_BASE64`: matching raw 32-byte Ed25519 public key;
- `IWEBIT_UPDATE_KEY_ID`: stable public-key identifier;
- `CI_KEYCHAIN_PASSWORD`: random password for temporary CI keychains.

Store all release secrets in the protected `apple-release` GitHub Environment
and require a reviewer. Keep command and update keys separate. The private
update key is used only to sign the manifest and is never placed in an app,
pkg, artifact or GitHub Release.

See `Documentation/Updates/AUTOMATIC_UPDATE_CHANNEL.md` for the installed agent
checks, private-repository alternative and safe key-rotation sequence.