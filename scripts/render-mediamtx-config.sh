#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/render-mediamtx-config.sh \
    --ip YOUR_MAC_IP \
    --cert local-generated/certs/mediamtx-rtmps.cert.pem \
    --key local-generated/certs/mediamtx-rtmps.key.pem \
    [--user lattecam_publish] \
    [--out local-generated/mediamtx.yml]

Creates a hardened MediaMTX config and a local credentials file.
The generated credentials file is ignored by git.
EOF
}

MAC_IP=""
CERT_PATH=""
KEY_PATH=""
PUBLISH_USER="lattecam_publish"
OUT_FILE="local-generated/mediamtx.yml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ip)
      MAC_IP="${2:-}"
      shift 2
      ;;
    --cert)
      CERT_PATH="${2:-}"
      shift 2
      ;;
    --key)
      KEY_PATH="${2:-}"
      shift 2
      ;;
    --user)
      PUBLISH_USER="${2:-}"
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$MAC_IP" || -z "$CERT_PATH" || -z "$KEY_PATH" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -f "$CERT_PATH" || ! -f "$KEY_PATH" ]]; then
  echo "Certificate or key file does not exist." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT_FILE")"

PUBLISH_PASSWORD="$(python3 - <<'PY'
import secrets
import string
alphabet = string.ascii_letters + string.digits
print(''.join(secrets.choice(alphabet) for _ in range(32)))
PY
)"
USER_HASH="sha256:$(printf '%s' "$PUBLISH_USER" | openssl dgst -binary -sha256 | openssl base64)"
PASS_HASH="sha256:$(printf '%s' "$PUBLISH_PASSWORD" | openssl dgst -binary -sha256 | openssl base64)"

python3 - "$MAC_IP" "$CERT_PATH" "$KEY_PATH" "$USER_HASH" "$PASS_HASH" "$OUT_FILE" <<'PY'
from pathlib import Path
import sys

mac_ip, cert_path, key_path, user_hash, pass_hash, out_file = sys.argv[1:]
template = Path("templates/mediamtx.yml.template").read_text()
rendered = (
    template
    .replace("__MAC_IP__", mac_ip)
    .replace("__RTMPS_CERT_PATH__", cert_path)
    .replace("__RTMPS_KEY_PATH__", key_path)
    .replace("__PUBLISH_USER_HASH__", user_hash)
    .replace("__PUBLISH_PASS_HASH__", pass_hash)
)
Path(out_file).write_text(rendered)
PY

CREDENTIALS_FILE="$(dirname "$OUT_FILE")/lattecam-publish-credentials.txt"
cat > "$CREDENTIALS_FILE" <<EOF
LatteCam publish credentials

Host: $MAC_IP
RTMPS connection: rtmps://$MAC_IP:1936/live
Stream name: lattecam?user=$PUBLISH_USER&pass=$PUBLISH_PASSWORD

Enter these in the iOS app:
  Mac host or IP: $MAC_IP
  Publish username: $PUBLISH_USER
  Publish password: $PUBLISH_PASSWORD
EOF
chmod 600 "$CREDENTIALS_FILE"

cat <<EOF
Rendered MediaMTX config:
  $OUT_FILE

Stored local publish credentials:
  $CREDENTIALS_FILE

The MediaMTX config contains only SHA-256 hashes. Do not commit local-generated/.
EOF

