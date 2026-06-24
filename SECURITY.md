# Security Policy

## Supported Scope

This project is a local-network template for:

- LatteCam iOS app source.
- MediaMTX RTMPS/RTSP configuration templates.
- Scrypted/HomeKit setup documentation.
- Local certificate and verification scripts.

It is not designed to expose camera streams, Scrypted, or MediaMTX directly to the public internet.

## Reporting Security Issues

Please open a private security advisory if the repository is hosted on GitHub and the issue could expose credentials, private keys, local streams, or HomeKit pairing data.

Do not post real passwords, private keys, HomeKit PINs, Scrypted database files, or full logs in a public issue.

## Sensitive Files

Never publish:

- `local-generated/`
- local CA private keys
- RTMPS server private keys
- generated certificate files
- Scrypted databases
- HomeKit `AccessoryInfo.*` or `IdentifierCache.*`
- HomeKit PINs
- real MediaMTX publish credentials
- local runbooks with real IPs or hostnames

Run before release:

```sh
scripts/security-check.sh
```

## Recommended Deployment

- Keep MediaMTX RTMPS on the trusted LAN only.
- Keep RTSP bound to `127.0.0.1`.
- Keep Scrypted behind the Mac firewall.
- Use Apple HomeKit remote access through a Home Hub for cellular viewing.
- Do not configure router port forwarding for this stack.

