# Scrypted and HomeKit Setup

This project uses Scrypted as the HomeKit bridge. MediaMTX exposes RTSP only on localhost, and Scrypted reads that local stream.

## Add the RTSP Camera

In Scrypted, install or enable the RTSP Camera plugin and add:

```text
rtsp://127.0.0.1:8554/live/lattecam
```

Keep the RTSP URL on localhost. Do not use the Mac LAN IP for this internal hop.

## HomeKit Plugin

Recommended setup:

- Enable the Scrypted HomeKit plugin.
- Expose `LatteCam` through the Scrypted HomeKit Bridge.
- Prefer Bridge mode for reliability.
- Use standalone accessory mode only after verifying pairing in your HomeKit environment.

Bridge mode is often more reliable for RTSP cameras because the bridge pairs once and then exposes the camera as a child accessory.

## Home App Pairing

Pair the Scrypted Bridge from the Apple Home app. After pairing, `LatteCam` should appear under the Bridge.

If pairing fails:

- Confirm the iPhone and Mac are on the same trusted LAN.
- Confirm the Mac firewall allows Scrypted/HomeKit traffic.
- Remove stale Scrypted or LatteCam accessories from the Home app.
- Restart Scrypted and try pairing the Bridge again.

## Remote Viewing

Local Wi-Fi viewing can work without a Home Hub. Cellular or off-LAN viewing requires a Home Hub such as:

- HomePod
- HomePod mini
- Apple TV

Do not expose Scrypted directly to the internet for remote viewing. Use Apple HomeKit remote access.

