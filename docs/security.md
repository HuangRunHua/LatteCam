# Security Model

LatteCam is designed for a trusted home LAN. It is not a public internet camera server.

## Protected Data Flow

```text
Old iPhone -> RTMPS -> MediaMTX -> localhost RTSP -> Scrypted -> HomeKit
```

Security defaults:

- iPhone to Mac uses RTMPS on port `1936`.
- Publishing requires a per-install username and password.
- The iOS app stores the publish password in Keychain.
- MediaMTX stores only SHA-256 hashes for publish credentials.
- RTSP is bound to `127.0.0.1:8554`, so LAN devices cannot directly pull the RTSP stream.
- Unused MediaMTX protocols are disabled by default in the template.
- Scrypted exposes the camera through HomeKit, which uses HomeKit encrypted streams.

## Never Commit

Do not commit:

- Local CA private keys.
- RTMPS server private keys.
- Generated `.cer`, `.cert.pem`, `.key.pem`, `.csr.pem`, or `.srl` files.
- MediaMTX configs containing real machine paths or hashes from a private setup.
- Scrypted database files.
- HomeKit `AccessoryInfo.*` or `IdentifierCache.*` files.
- HomeKit PINs.
- Real publish passwords.
- Local runbooks with real IPs, hostnames, or pairing state.

Run before publishing:

```sh
scripts/security-check.sh
```

## Network Rules

Do not forward these ports to the public internet:

- `1936` RTMPS
- `8554` RTSP
- `10443` Scrypted UI
- Scrypted HomeKit Bridge ports

Use the system firewall. Avoid guest Wi-Fi, office Wi-Fi, hotel Wi-Fi, and shared untrusted LANs.

## HomeKit Remote Access

Remote viewing from cellular networks requires a Home Hub such as a HomePod or Apple TV. Remote access should go through Apple HomeKit, not through direct public exposure of Scrypted or MediaMTX.

## Certificate Trust

Use `scripts/generate-local-ca.sh` to generate a local CA and MediaMTX server certificate. Install the generated CA certificate on the old iPhone and enable full trust:

```text
Settings > General > About > Certificate Trust Settings
```

If RTMPS keeps reconnecting and MediaMTX logs `tls: bad certificate`, the iPhone does not trust the CA or the server certificate SAN does not match the host used by the app.

