# Automatic update channels

## macOS

The macOS 2.0 daemon reads the root-owned configuration installed at:

`/Library/Application Support/iWebITAgent/update-channel.json`

Every configured interval (six hours in the release workflow), it downloads
the latest signed manifest. It installs only when all of these checks pass:

1. the channel configuration is owned by root and is not group/world writable;
2. the manifest is fetched over HTTPS and is at most 1 MiB;
3. its Ed25519 signature matches a public key embedded in the signed pkg;
4. the candidate build is newer than the installed build;
5. the current macOS version satisfies the minimum version;
6. the downloaded pkg size and SHA-256 match the signed manifest;
7. `pkgutil` reports the expected Apple Developer Team ID;
8. Gatekeeper accepts the notarized installer.

The release tag is immutable: `v<marketing-version>-<build>`. The manifest
inside that release points to the pkg in the same release. The agent discovers
the channel through GitHub's `releases/latest/download/update-manifest.json`
redirect, but it does not trust GitHub as the signing authority.

Existing legacy agents and earlier 2.0 builds that do not contain this
coordinator need one manually installed signed pkg to bootstrap the automatic
channel. Later releases can update through the channel.

The repository must be public for an unauthenticated installed agent to
download GitHub Release assets. For a private repository, publish the same
signed manifest and pkg through an authenticated backend or HTTPS CDN; never
embed a GitHub token in the agent.

## iOS and iPadOS

A normal iOS/iPadOS app cannot replace its own installed binary from a GitHub
Release. The GitHub workflow can build and sign the universal IPA and,
optionally, upload it to App Store Connect. Distribution then uses TestFlight
or the App Store.

Set `upload_to_testflight` when manually starting the workflow. The App Store
Connect application record and an App Store distribution provisioning profile
must already exist. Use a team API key, not an individual API key.

TestFlight group assignment and external beta review remain Apple-side
operations. Configure automatic distribution for the desired internal group
in App Store Connect if every processed CI build should be offered to testers.

## Key rotation

The private Ed25519 update key exists only as a protected GitHub secret. The
matching public key is embedded in the signed pkg configuration. To rotate:

1. release a transition pkg containing both old and new public keys;
2. confirm that supported agents installed it;
3. sign later manifests with the new key ID;
4. remove the old key in a subsequent signed release.

Do not reuse the command-signing key as the update-signing key.
