---
name: lattecam-bootstrap
description: Use when setting up LatteCam, MediaMTX, Scrypted, or HomeKit from this repository.
---

# LatteCam Bootstrap

Follow the secure local setup path. Do not expose MediaMTX or Scrypted to the public internet.

1. Read `README.md`, `QUICKSTART.md`, and `docs/security.md`.
2. Confirm required tools are available: Xcode, XcodeGen, Homebrew, MediaMTX, Scrypted, OpenSSL, and optionally FFmpeg.
3. Generate local certificates:

```sh
scripts/generate-local-ca.sh --host YOUR_MAC_HOST.local --ip YOUR_MAC_IP
```

4. Render MediaMTX config:

```sh
scripts/render-mediamtx-config.sh --ip YOUR_MAC_IP --cert local-generated/certs/mediamtx-rtmps.cert.pem --key local-generated/certs/mediamtx-rtmps.key.pem
```

5. Install and fully trust `local-generated/certs/lattecam-local-ca.cer` on the old iPhone.
6. Configure MediaMTX from `local-generated/mediamtx.yml`.
7. Generate the Xcode project with `xcodegen generate`, set the user's own signing team in Xcode, build, and install LatteCam.
8. Add `rtsp://127.0.0.1:8554/live/lattecam` to Scrypted and expose it through the HomeKit Bridge.
9. Run `scripts/verify-local-stack.sh YOUR_MAC_IP`.

Never commit generated certs, credentials, Scrypted state, HomeKit PINs, or local runbooks.

