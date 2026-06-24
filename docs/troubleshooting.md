# Troubleshooting

Debug the chain from left to right:

```text
iPhone App -> RTMPS -> MediaMTX -> RTSP localhost -> Scrypted -> HomeKit
```

## iPhone Stuck Reconnecting

Check MediaMTX logs.

If you see:

```text
RTMPS closed: remote error: tls: bad certificate
```

Fix:

- Install the generated local CA on the iPhone.
- Enable full trust in certificate trust settings.
- Make sure the app host matches a SAN in the server certificate.

If you see:

```text
authentication failed
```

Fix:

- Re-enter the publish username and password in the iOS app.
- Confirm the username is `lattecam_publish` unless you rendered a different one.
- Confirm the app uses `rtmps://HOST:1936/live` and publishes `lattecam?user=...&pass=...`.

## Scrypted Shows No Video

Check whether MediaMTX has a published stream:

```sh
scripts/verify-local-stack.sh YOUR_MAC_IP
```

If Scrypted logs:

```text
RTSP/1.0 404 Not Found
```

MediaMTX has no active publisher on `live/lattecam`. Fix the iPhone RTMPS publish path first.

## RTSP Works But HomeKit Is Blank

Check Scrypted logs for:

```text
first video packet
idr start found
handleStreamRequest
```

If these appear, Scrypted is receiving and forwarding video. Restart the Home app or reopen the camera tile.

## HomeKit Pairing Times Out

Use Bridge mode first:

- Pair the Scrypted HomeKit Bridge.
- Let `LatteCam` appear as a child camera.
- Avoid standalone camera pairing until the bridge path is stable.

If a Home says the accessory is already added elsewhere, remove stale Scrypted or LatteCam accessories from old Homes, or reset the Scrypted HomeKit pairing identity.

## 5G or Off-LAN Viewing Fails

Remote viewing requires an Apple Home Hub. Local Wi-Fi viewing may work without one, but cellular viewing needs HomePod, HomePod mini, or Apple TV online in the Home.

