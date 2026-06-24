# Quick Start

This guide sets up the secure local path:

```text
iPhone -> RTMPS -> MediaMTX -> RTSP localhost -> Scrypted -> HomeKit
```

## 1. Install Tools

On the Mac:

```sh
brew install mediamtx xcodegen ffmpeg
```

Use Xcode 26.5 or newer. LatteCam currently uses HaishinKit 2.2.x, which requires Xcode 26+.

Install Scrypted from the official instructions:

```text
https://www.scrypted.app/
```

## 2. Choose Local Values

Replace these placeholders:

```text
YOUR_MAC_HOST.local
YOUR_MAC_IP
```

Use a stable LAN IP for the Mac, ideally via DHCP reservation on your router.

## 3. Generate Local Certificates

```sh
scripts/generate-local-ca.sh --host YOUR_MAC_HOST.local --ip YOUR_MAC_IP
```

Install `local-generated/certs/lattecam-local-ca.cer` on the old iPhone, then enable full trust:

```text
Settings > General > About > Certificate Trust Settings
```

## 4. Render MediaMTX Config

```sh
scripts/render-mediamtx-config.sh \
  --ip YOUR_MAC_IP \
  --cert local-generated/certs/mediamtx-rtmps.cert.pem \
  --key local-generated/certs/mediamtx-rtmps.key.pem
```

Copy the generated config to your MediaMTX config path:

```sh
sudo cp local-generated/mediamtx.yml /opt/homebrew/etc/mediamtx/mediamtx.yml
brew services restart mediamtx
```

The generated publish credentials are in:

```text
local-generated/lattecam-publish-credentials.txt
```

Do not commit `local-generated/`.

## 5. Build the iOS App

```sh
xcodegen generate
open LatteCam.xcodeproj
```

In Xcode:

- Select the `LatteCam` target.
- Set your own Team.
- Set your own bundle identifier if needed.
- Build and install on the old iPhone.

In the LatteCam app, enter:

```text
Mac host or IP: YOUR_MAC_IP or YOUR_MAC_HOST.local
Application: live
Stream name: lattecam
Publish username: from local-generated/lattecam-publish-credentials.txt
Publish password: from local-generated/lattecam-publish-credentials.txt
```

## 6. Configure Scrypted

Add an RTSP Camera in Scrypted:

```text
rtsp://127.0.0.1:8554/live/lattecam
```

Expose it through the Scrypted HomeKit plugin in Bridge mode.

## 7. Add to Apple Home

Pair the Scrypted HomeKit Bridge in the Home app. `LatteCam` should appear as a camera under the bridge.

For cellular or off-LAN viewing, keep a Home Hub online:

- HomePod
- HomePod mini
- Apple TV

## 8. Verify

```sh
scripts/verify-local-stack.sh YOUR_MAC_IP
scripts/security-check.sh
```

If verification fails, use `docs/troubleshooting.md`.

