# iWebIT API security protocol v2

All production endpoints must use HTTPS. Cleartext HTTP is accepted only for an
explicit localhost test environment.

## Device enrollment

1. The app creates a random device key locally.
2. The user authenticates the enrollment with the company `IDSync`.
3. The server returns a stable `deviceID`, a revocable `keyID`, a per-device
   256-bit secret, and the current server/update public keys.
4. The client stores credentials in Keychain using
   `AfterFirstUnlockThisDeviceOnly`.
5. `IDSync` is no longer used as an ongoing bearer credential.
6. The mobile app derives a salted local verifier after enrollment. IDSYNC is
   requested again only to unlock local diagnostics or authorize logout; it is
   never written to logs or stored in plain text.

Production mobile enrollment should use App Attest where applicable. macOS
enrollment should use an appropriate signed-client attestation design. Both
flows must be rate-limited and auditable.

## Authenticated requests

Every request contains:

- `X-iWebIT-Protocol: 1`
- `X-iWebIT-Device-ID`
- `X-iWebIT-Key-ID`
- `X-iWebIT-Timestamp`
- `X-iWebIT-Nonce`
- `X-iWebIT-Content-SHA256`
- `X-iWebIT-Signature`

The signature is HMAC-SHA256 of:

```text
UPPERCASE_HTTP_METHOD
/percent-encoded/path
query-items-sorted-by-name-and-value
unix-timestamp
lowercase-uuid-nonce
lowercase-body-sha256
```

The server must reject an unknown/revoked key, a reused nonce, an invalid body
hash, or a timestamp outside a short clock-skew window.

## Commands

Commands are signed by an offline-controlled Ed25519 key and contain:

- unique command and nonce identifiers;
- issue, activation, and expiry times;
- exact target device;
- command type and opaque payload;
- signing key identifier.

Agents verify the signature, target, validity window, authorization policy, and
nonce before execution. Destructive commands must also have an audit event and
an explicit server-side authorization decision.

## Updates

The API returns a signed update manifest containing version, build, HTTPS URL,
byte count, SHA-256, minimum OS, and signing key ID. The macOS adapter must
verify, in this order:

1. manifest Ed25519 signature;
2. HTTPS URL, byte count, and SHA-256;
3. package signature and expected Apple Developer Team ID;
4. notarization/Gatekeeper assessment;
5. version policy and rollback protection.

Only then may the privileged service invoke the system installer.

### Command transport

- `GET /v2/devices/commands?after=<cursor>` returns `PendingCommandsResponse`.
- `POST /v2/devices/commands/<command-id>/result` accepts the terminal or
  user-action result.

Both calls use the per-device HMAC authentication above. APNs may signal that
work is available but never carries authorization by itself. The device must
still fetch or decode a complete `SignedCommand`, verify it, and atomically
consume its nonce before dispatch. Invalid signatures are security events and
must not be converted into successful acknowledgements.