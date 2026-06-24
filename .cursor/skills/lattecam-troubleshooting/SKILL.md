---
name: lattecam-troubleshooting
description: Use when LatteCam reconnects, Scrypted has no video, RTSP is 404, RTMPS TLS fails, or HomeKit pairing times out.
---

# LatteCam Troubleshooting

Read `docs/troubleshooting.md` first. Debug in this order:

```text
iPhone App -> RTMPS -> MediaMTX -> RTSP localhost -> Scrypted -> HomeKit
```

Core checks:

- If MediaMTX logs `tls: bad certificate`, verify the iPhone trusts the generated local CA and the app host matches the certificate SAN.
- If MediaMTX logs `authentication failed`, verify the app publishes stream name `lattecam?user=...&pass=...`.
- If Scrypted sees RTSP 404, the iPhone is not publishing to `live/lattecam`.
- If RTSP works but HomeKit is blank, inspect Scrypted logs for stream request and video packet events.
- If HomeKit pairing times out, prefer Scrypted HomeKit Bridge mode before standalone accessory mode.
- If cellular viewing fails, confirm a HomePod or Apple TV is acting as Home Hub.

Use this script for quick local evidence:

```sh
scripts/verify-local-stack.sh YOUR_MAC_IP
```

Do not reset Scrypted or HomeKit identity files unless the user explicitly asks and understands it may require re-pairing.

