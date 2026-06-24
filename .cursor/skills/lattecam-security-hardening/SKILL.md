---
name: lattecam-security-hardening
description: Use when the user asks about LatteCam security, RTMPS, certificates, firewall, or safe publishing.
---

# LatteCam Security Hardening

Start by reading `docs/security.md` and `templates/mediamtx.yml.template`.

Required checks:

- MediaMTX publishing requires authentication.
- MediaMTX RTMPS is enabled with `rtmpEncryption: "strict"`.
- RTSP is bound to `127.0.0.1:8554`.
- HLS, WebRTC, SRT, MoQ, playback, metrics, API, and pprof are disabled unless the user explicitly needs them.
- `overridePublisher` is false.
- iOS publish password is stored in Keychain, not UserDefaults.
- Scrypted is not exposed through router port forwarding.
- No local CA private key, RTMPS server key, Scrypted database, HomeKit PIN, or local runbook is committed.

Before declaring the setup ready for GitHub or production-like use, run:

```sh
scripts/security-check.sh
```

If the user wants remote viewing, guide them toward Apple HomeKit remote access through a Home Hub. Do not recommend direct public exposure of MediaMTX or Scrypted.

