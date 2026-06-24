#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

files=()

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r file; do
    files+=("$file")
  done < <(git ls-files -co --exclude-standard)
else
  while IFS= read -r file; do
    files+=("$file")
  done < <(
    find . -type f \
      -not -path './.git/*' \
      -not -path './LatteCam.xcodeproj/*' \
      -not -path './runbook.md' \
      -not -path './local-generated/*' \
      -not -path './.cursor/plans/*' \
      -not -path './.cursor/canvases/*'
  )
fi

failures=0

report() {
  printf 'SECURITY CHECK FAILED: %s\n' "$1" >&2
  failures=$((failures + 1))
}

for file in "${files[@]}"; do
  case "$file" in
    ./scripts/security-check.sh|scripts/security-check.sh)
      continue
      ;;
  esac

  case "$file" in
    *.key|*.key.pem|*.csr|*.csr.pem|*.srl|*.cer|*.crt|*.crt.pem|*.cert.pem)
      report "certificate or private-key artifact is tracked: $file"
      ;;
    *scrypted.db*|*AccessoryInfo.*|*IdentifierCache.*)
      report "Scrypted/HomeKit local state is tracked: $file"
      ;;
    *runbook.md)
      report "local runbook must not be tracked: $file"
      ;;
  esac

  if [[ -f "$file" ]] && grep -Iq . "$file"; then
    if grep -Eq 'BEGIN ((RSA|EC|OPENSSH) )?PRIVATE KEY' "$file"; then
      report "private key material found in $file"
    fi
    if grep -Eq '\b[0-9]{3}-[0-9]{2}-[0-9]{3}\b' "$file"; then
      report "HomeKit-style PIN found in $file"
    fi
    if grep -Eq '172\.17\.17\.234|Runhuas-MacBook-Pro-5\.local|YRB62S584T|LatteCamBonjour|Scrypted (0ABE|F2D8|FF6C)' "$file"; then
      report "machine-specific LatteCam value found in $file"
    fi
  fi
done

if (( failures > 0 )); then
  printf '\nFix the issues above before publishing this repository.\n' >&2
  exit 1
fi

printf 'Security check passed: no obvious local secrets or machine-bound artifacts found.\n'

