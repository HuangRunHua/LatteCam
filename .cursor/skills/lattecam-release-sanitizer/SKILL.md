---
name: lattecam-release-sanitizer
description: Use before committing, releasing, or publishing LatteCam to GitHub.
---

# LatteCam Release Sanitizer

Before commit, release, or GitHub template publication:

1. Run `scripts/security-check.sh`.
2. Confirm `.gitignore` excludes generated certificates, local runbooks, Scrypted state, Xcode user state, and generated local configs.
3. Confirm docs use placeholders such as `YOUR_MAC_IP` and `YOUR_MAC_HOST.local`.
4. Confirm `project.yml` does not contain a personal `DEVELOPMENT_TEAM`.
5. Confirm `StreamConfiguration.default` has no personal Mac hostname or LAN IP.
6. Confirm no generated `.cer`, `.key.pem`, `.csr.pem`, `.cert.pem`, `.srl`, `.log`, or `scrypted.db` files are staged.
7. Confirm HomeKit PINs are not present anywhere in tracked files.

If any check fails, stop the release and remove or template the sensitive value. Do not commit real local credentials or pairing state.

