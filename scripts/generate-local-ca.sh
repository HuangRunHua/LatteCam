#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/generate-local-ca.sh --host YOUR_MAC_HOST.local --ip YOUR_MAC_IP [--out local-generated/certs]

Generates:
  - lattecam-local-ca.cert.pem
  - lattecam-local-ca.cer
  - mediamtx-rtmps.cert.pem
  - mediamtx-rtmps.key.pem

Install lattecam-local-ca.cer on the iPhone and fully trust it before using RTMPS.
EOF
}

HOST=""
IP=""
OUT_DIR="local-generated/certs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:-}"
      shift 2
      ;;
    --ip)
      IP="${2:-}"
      shift 2
      ;;
    --out)
      OUT_DIR="${2:-}"
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

if [[ -z "$HOST" || -z "$IP" ]]; then
  usage >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

CA_KEY="$OUT_DIR/lattecam-local-ca.key.pem"
CA_CERT="$OUT_DIR/lattecam-local-ca.cert.pem"
CA_DER="$OUT_DIR/lattecam-local-ca.cer"
SERVER_KEY="$OUT_DIR/mediamtx-rtmps.key.pem"
SERVER_CSR="$OUT_DIR/mediamtx-rtmps.csr.pem"
SERVER_CERT="$OUT_DIR/mediamtx-rtmps.cert.pem"
SERVER_EXT="$OUT_DIR/mediamtx-rtmps.ext"

openssl genrsa -out "$CA_KEY" 4096
openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 3650 \
  -subj "/CN=LatteCam Local CA/O=LatteCam" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -out "$CA_CERT"

cat > "$SERVER_EXT" <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:${HOST},DNS:localhost,IP:${IP},IP:127.0.0.1
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

openssl genrsa -out "$SERVER_KEY" 2048
openssl req -new -key "$SERVER_KEY" \
  -subj "/CN=${HOST}/O=LatteCam" \
  -out "$SERVER_CSR"
openssl x509 -req -in "$SERVER_CSR" \
  -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
  -out "$SERVER_CERT" -days 397 -sha256 -extfile "$SERVER_EXT"
openssl x509 -in "$CA_CERT" -outform der -out "$CA_DER"

chmod 600 "$CA_KEY" "$SERVER_KEY"
chmod 644 "$CA_CERT" "$CA_DER" "$SERVER_CERT"

cat <<EOF
Generated LatteCam local certificates:
  CA certificate for iPhone: $CA_DER
  MediaMTX server cert:     $SERVER_CERT
  MediaMTX server key:      $SERVER_KEY

Next:
  1. Install $CA_DER on the old iPhone.
  2. Enable full trust in Settings > General > About > Certificate Trust Settings.
  3. Use the cert/key paths when rendering MediaMTX config.
EOF

