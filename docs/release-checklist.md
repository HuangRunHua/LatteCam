# Release Checklist

Run this before publishing LatteCam as a GitHub template repository.

## Required Checks

- `scripts/security-check.sh` passes.
- `bash -n scripts/*.sh` passes.
- `xcodegen generate` succeeds.
- `xcodebuild` succeeds with `CODE_SIGNING_ALLOWED=NO`.
- `.gitignore` excludes generated certs, local runbooks, Scrypted state, and Xcode user state.
- `project.yml` has no personal `DEVELOPMENT_TEAM`.
- iOS defaults use placeholders, not a real Mac hostname or LAN IP.
- Docs use `YOUR_MAC_IP` and `YOUR_MAC_HOST.local`.
- `local-generated/` is absent from git.
- No `.cer`, `.key.pem`, `.csr.pem`, `.cert.pem`, `.srl`, `.log`, `scrypted.db`, `AccessoryInfo.*`, or `IdentifierCache.*` files are tracked.
- No HomeKit PIN appears in tracked files.

## GitHub Template Settings

After pushing the sanitized repository:

1. Open repository settings.
2. Enable `Template repository`.
3. Set the repository description to:

   ```text
   Turn an old iPhone into a secure local HomeKit camera using SwiftUI, RTMPS, MediaMTX, Scrypted, and HomeKit.
   ```

4. Add topics:

   ```text
   homekit, scrypted, mediamtx, rtmps, swiftui, ios, iphone-camera, homekit-camera, local-first, security, smarthome, cursor-skills
   ```

5. Keep Issues enabled for setup and troubleshooting questions.
6. Keep Actions enabled so CI validates the template.
7. Keep private vulnerability reporting and security advisories enabled.

See `docs/repository-metadata.md` for copyable GitHub CLI commands.

