#!/usr/bin/env bash
set -euo pipefail

RTMPS_HOST="${1:-127.0.0.1}"
RTMPS_PORT="${2:-1936}"
RTSP_URL="${3:-rtsp://127.0.0.1:8554/live/lattecam}"

run_with_timeout() {
  local seconds="$1"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$seconds" "$@"
  else
    "$@"
  fi
}

echo "LatteCam local stack verification"
echo

echo "1. Listening ports"
lsof -nP -iTCP:"$RTMPS_PORT" -sTCP:LISTEN || true
lsof -nP -iTCP:8554 -sTCP:LISTEN || true
lsof -nP -iTCP:10443 -sTCP:LISTEN || true

echo
echo "2. RTMPS TLS handshake"
if command -v openssl >/dev/null 2>&1; then
  run_with_timeout 8 openssl s_client -connect "${RTMPS_HOST}:${RTMPS_PORT}" -servername "$RTMPS_HOST" </dev/null 2>/tmp/lattecam-rtmps-verify.log | sed -n '1,16p' || true
  grep -E 'subject=|issuer=|Verify return code' /tmp/lattecam-rtmps-verify.log || true
else
  echo "openssl not found"
fi

echo
echo "3. RTSP availability"
if command -v ffprobe >/dev/null 2>&1; then
  run_with_timeout 8 ffprobe -v error -show_streams "$RTSP_URL" || true
else
  echo "ffprobe not found; install ffmpeg or use Scrypted/VLC to verify $RTSP_URL"
fi

echo
echo "4. Expected secure topology"
echo "iPhone -> RTMPS ${RTMPS_HOST}:${RTMPS_PORT} -> MediaMTX -> RTSP 127.0.0.1:8554 -> Scrypted -> HomeKit"

