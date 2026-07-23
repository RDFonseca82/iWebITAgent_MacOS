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

Create these as Environment secrets in repository **Settings > Environments >
apple-release > Environment secrets**. Values shown below are descriptions or
examples; never copy a placeholder literally.

| Secret | Exact value to store |
| --- | --- |
| `APPLE_TEAM_ID` | The 10-character Apple Developer Team ID, for example `A1B2C3D4E5`. |
| `CI_KEYCHAIN_PASSWORD` | A new random password used only for the temporary CI keychain, generated for example with `openssl rand -base64 32`. |
| `DEVELOPER_ID_APPLICATION_IDENTITY` | Full certificate common name, for example `Developer ID Application: Company Name (A1B2C3D4E5)`. |
| `DEVELOPER_ID_INSTALLER_IDENTITY` | Full certificate common name, for example `Developer ID Installer: Company Name (A1B2C3D4E5)`. |
| `DEVELOPER_ID_APPLICATION_P12_BASE64` | Base64 of the `.p12` export containing the Developer ID Application certificate and its private key. |
| `DEVELOPER_ID_INSTALLER_P12_BASE64` | Base64 of the `.p12` export containing the Developer ID Installer certificate and its private key. |
| `DEVELOPER_ID_P12_PASSWORD` | Password used when exporting both macOS `.p12` files. Export both with the same strong password because the workflow uses this one secret for both. |
| `NOTARY_KEY_ID` | Key ID displayed for the App Store Connect team API key, for example `AB12C3D4E5`. |
| `NOTARY_ISSUER_ID` | Issuer ID UUID displayed in App Store Connect, for example `11111111-2222-3333-4444-555555555555`. |
| `NOTARY_PRIVATE_KEY_BASE64` | Base64 of the downloaded `AuthKey_<KEY_ID>.p8` team API private-key file. |
| `IOS_DISTRIBUTION_P12_BASE64` | Base64 of a `.p12` export containing the Apple Distribution certificate and its private key. |
| `IOS_DISTRIBUTION_P12_PASSWORD` | Password used when exporting the iOS Apple Distribution `.p12`. |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64 of an App Store distribution provisioning profile for bundle ID `app.iwebit.mobile`. |
| `IWEBIT_UPDATE_PRIVATE_KEY_BASE64` | Base64 of the raw 32-byte CryptoKit `Curve25519.Signing.PrivateKey` representation. |
| `IWEBIT_UPDATE_PUBLIC_KEY_BASE64` | Base64 of the matching raw 32-byte CryptoKit public-key representation. |
| `IWEBIT_UPDATE_KEY_ID` | A stable identifier chosen by the project, such as `iwebit-update-2026-01`; it is not a secret but is stored here with the key pair. |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect team API key ID. Required only when `upload_to_testflight` is enabled. |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID UUID for that team API key. Required only for TestFlight. |
| `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` | Base64 of its downloaded `.p8` file. Required only for TestFlight. |

Use a team API key rather than an individual key for notarization. The same
appropriately privileged team key may be stored under both the `NOTARY_*` and
`APP_STORE_CONNECT_*` names, although separate keys reduce blast radius. The
application record and bundle identifier must already exist in App Store
Connect before a TestFlight upload.

## Preparing file secrets on a trusted Mac

Export each certificate from **Keychain Access > My Certificates** together
with its private key as `.p12`. Then produce a one-line Base64 value:

```bash
base64 < developer-id-application.p12 | tr -d '\n'
base64 < developer-id-installer.p12 | tr -d '\n'
base64 < ios-distribution.p12 | tr -d '\n'
base64 < iWebITMobile.mobileprovision | tr -d '\n'
base64 < AuthKey_AB12C3D4E5.p8 | tr -d '\n'
```

Paste each command's output into the matching GitHub Environment secret. Do
not commit the `.p12`, `.p8`, provisioning profile, Base64 output or passwords.
Delete unnecessary local export copies after confirming the release workflow.

Generate the update signing pair once on a trusted Mac:

```bash
swift scripts/release/generate-update-signing-key.swift
```

Copy its two outputs into `IWEBIT_UPDATE_PRIVATE_KEY_BASE64` and
`IWEBIT_UPDATE_PUBLIC_KEY_BASE64`, choose a stable `IWEBIT_UPDATE_KEY_ID`, and
keep an encrypted offline backup. Never reuse this key as a remote-command
signing key. Private and public values must come from the same generation.

The workflow validates only that values exist. Apple subsequently verifies that
certificates contain private keys, passwords are correct, identities and Team ID
match, the profile belongs to `app.iwebit.mobile`, and API-key permissions are
sufficient.

Official references:

- GitHub environment secrets: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets
- Apple Developer ID certificates: https://developer.apple.com/help/account/certificates/create-developer-id-certificates/
- App Store Connect team API keys: https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api
- Apple notarization API-key arguments: https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool

Store all release secrets in the protected `apple-release` GitHub Environment
and require a reviewer. Keep command and update keys separate. The private
update key is used only to sign the manifest and is never placed in an app,
pkg, artifact or GitHub Release.

See `Documentation/Updates/AUTOMATIC_UPDATE_CHANNEL.md` for the installed agent
checks, private-repository alternative and safe key-rotation sequence.