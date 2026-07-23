# macOS release gate

A production package is releasable only when all gates pass:

1. Release builds use Hardened Runtime and no `get-task-allow`.
2. Every app, helper and executable is signed with the expected Developer ID
   Application identity and a secure timestamp.
3. The final flat package is signed with Developer ID Installer.
4. `pkgutil --check-signature` shows the expected Team ID.
5. `spctl --assess --type install` accepts the package.
6. `xcrun notarytool submit --wait` succeeds and its log contains no unresolved
   warnings.
7. The notarization ticket is stapled and validated.
8. A clean supported Mac installs, launches, upgrades and uninstalls the package.
9. The signed update manifest SHA-256 matches the final notarized package.

Store notarization credentials in a dedicated Keychain profile:

```bash
xcrun notarytool store-credentials iwebit-notary
export IWEBIT_NOTARY_KEYCHAIN_PROFILE=iwebit-notary
scripts/release/notarize-package.sh /absolute/path/to/iWebIT.pkg
```

Do not store Apple IDs, app-specific passwords, API private keys, certificates
or update signing private keys in this repository.
