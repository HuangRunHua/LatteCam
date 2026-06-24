# Repository Metadata

Use this file when publishing LatteCam to GitHub or turning it into a template repository.

## Suggested Description

Turn an old iPhone into a secure local HomeKit camera using SwiftUI, RTMPS, MediaMTX, Scrypted, and HomeKit.

## Suggested Topics

`homekit`, `scrypted`, `mediamtx`, `rtmps`, `swiftui`, `ios`, `iphone-camera`, `homekit-camera`, `local-first`, `security`, `smarthome`, `cursor-skills`

## Suggested About Text

LatteCam is a local-first HomeKit camera template. The iOS app publishes authenticated RTMPS to MediaMTX, MediaMTX exposes localhost-only RTSP, and Scrypted bridges the stream into Apple HomeKit.

## Recommended GitHub Settings

- Enable Template repository.
- Enable private vulnerability reporting and security advisories.
- Keep Issues enabled for setup and troubleshooting questions.
- Keep Actions enabled so CI can run `scripts/security-check.sh`, shell syntax checks, XcodeGen, and an unsigned iOS build.
- Do not upload local runbooks, generated certificates, Scrypted databases, HomeKit pairing files, or real publish credentials.

## GitHub CLI Setup

After creating the GitHub repository and adding a remote, you can apply the public metadata with:

```sh
gh repo edit --description "Turn an old iPhone into a secure local HomeKit camera using SwiftUI, RTMPS, MediaMTX, Scrypted, and HomeKit." \
  --add-topic homekit \
  --add-topic scrypted \
  --add-topic mediamtx \
  --add-topic rtmps \
  --add-topic swiftui \
  --add-topic ios \
  --add-topic iphone-camera \
  --add-topic homekit-camera \
  --add-topic local-first \
  --add-topic security \
  --add-topic smarthome \
  --add-topic cursor-skills
```

Run `scripts/security-check.sh` again before making the repository public.
