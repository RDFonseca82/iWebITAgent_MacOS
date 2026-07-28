# macOS App Store / TestFlight edition

The repository contains two independent macOS products:

| Edition | Target | Delivery | Capabilities |
| --- | --- | --- | --- |
| Full agent | `iWebITAgent` plus daemon | Signed and notarized GitHub `.pkg` | Full synchronization and explicitly authorized administrative commands |
| App Store | `iWebITMacStore` | TestFlight and Mac App Store | Sandboxed synchronization, support tickets and notifications only |

The App Store target never runs the privileged daemon. It does not restart or
shut down the Mac, remove applications, take screenshots, collect location,
enumerate installed applications/services, or use the GitHub `.pkg` updater.
Updates are delivered by the Mac App Store.

It supports macOS 11 or newer and uses the same schema 2.0 backend endpoints,
HTTPS device authentication and bundle ID `app.iwebit.mobile` as the universal
iPhone/iPad app.

## 1. Add macOS to the existing App Store Connect record

In App Store Connect:

1. Open **My Apps > iWebIT Agent** (Apple ID `6793997341`).
2. Choose **Add Platform** and select **macOS**.
3. Use bundle ID `app.iwebit.mobile`. Keep the existing SKU
   `iwebit-mobile-001`; adding a platform does not create a new SKU.
4. Create the macOS version matching the workflow marketing version, initially
   `2.0.0`.
5. Complete the macOS screenshots, description, privacy answers, age rating,
   support URL and review information.

Do not create another App Store Connect app with a different bundle ID. This
target is the macOS platform of the existing universal app record.

In Apple Developer **Certificates, Identifiers & Profiles**, open
`app.iwebit.mobile`, enable Push Notifications and save. Create/download a
**Mac App Store Connect** distribution provisioning profile for that identifier
and the Apple Distribution certificate used by CI.

## 2. GitHub Environment secrets

Store the following in **Repository Settings > Environments > apple-release >
Environment secrets**.

| Secret | Value |
| --- | --- |
| `APPLE_TEAM_ID` | The 10-character Apple Developer Team ID. |
| `IOS_DISTRIBUTION_P12_BASE64` | Existing Base64 Apple Distribution `.p12`; the same certificate signs iOS, iPadOS and this macOS app. |
| `IOS_DISTRIBUTION_P12_PASSWORD` | Password of that Apple Distribution `.p12`. |
| `MAC_INSTALLER_DISTRIBUTION_P12_BASE64` | Base64 `.p12` containing the Mac Installer Distribution certificate and its private key. |
| `MAC_INSTALLER_DISTRIBUTION_P12_PASSWORD` | Password used to export the Mac Installer Distribution `.p12`. |
| `MAC_APP_STORE_PROVISIONING_PROFILE_BASE64` | Base64 of the Mac App Store Connect profile for `app.iwebit.mobile`. |
| `CI_KEYCHAIN_PASSWORD` | Random password used only for the temporary runner keychain. |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect team API key ID. |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer UUID for that API key. |
| `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` | Base64 of `AuthKey_<KEY_ID>.p8`. |

The API key needs App Manager access to upload builds. Keep the private key,
certificate private keys and passwords out of the repository.

### Convert files to Base64 on Windows PowerShell

Run each command from the directory containing the file and paste the clipboard
contents into the matching secret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AppleDistribution.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("MacInstallerDistribution.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("iWebITMacStore.provisionprofile")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_AB12C3D4E5.p8")) | Set-Clipboard
```

If a new certificate must be created without a Mac, generate its private key and
CSR with OpenSSL on Windows, upload the CSR in Apple Developer, download the
certificate, then create the `.p12` with the same private key:

```powershell
openssl genrsa -out mac-installer-private.key 2048
openssl req -new -key mac-installer-private.key -out mac-installer.csr
openssl x509 -inform DER -in mac_installer_distribution.cer -out mac-installer.cer.pem
openssl pkcs12 -export -inkey mac-installer-private.key -in mac-installer.cer.pem -out MacInstallerDistribution.p12
```

Protect and back up the private key until the `.p12` is confirmed. Then remove
unencrypted working copies from the Windows machine.

## 3. Build and upload from GitHub

Open **Actions > Apple signed release and update channel > Run workflow**:

- `version`: `2.0.0` for the first upload;
- `build`: a positive number not previously uploaded for this macOS version;
- `upload_to_testflight`: controls the iPhone/iPad upload;
- `build_macos_app_store`: set to `true` only after all three `MAC_*`
  secrets in the table above have been configured;
- `upload_macos_to_testflight`: set to `true`.

The `macos-app-store` job validates the profile bundle ID, archives the
sandboxed app, checks sandbox/network/APNs entitlements, exports a
Mac Installer Distribution-signed package, validates it with Apple and uploads
it. The package is also retained as the
`iWebIT-macOS-AppStore-<version>-<build>` GitHub Actions artifact.

Both macOS App Store options default to `false` so an iPhone/iPad or full-agent
release is not blocked while the additional Mac Installer Distribution
certificate and Mac App Store profile are still being prepared. Enabling
`build_macos_app_store` keeps the three `MAC_*` secrets mandatory; the workflow
does not bypass or replace Apple signing.

After upload, Apple processing can take several minutes. In App Store Connect,
open **TestFlight > macOS** and answer any export-compliance question. Internal
testing can then be enabled.

Uploading is not production publication. For production, select the processed
macOS build under the macOS version page, complete all required metadata, click
**Add for Review**, and submit it. Apple review cannot be bypassed. Automatic
release after approval can be selected in the version release options.
