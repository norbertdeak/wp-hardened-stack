#!/usr/bin/env bash
# Generate secrets into .env without ever printing them to the terminal history.
set -Eeuo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] || { echo "✗ előbb: cp .env.example .env"; exit 1; }

gen() { openssl rand -base64 32 | tr -d '/+=' | cut -c1-32; }

fill() {
  local key="$1" val
  if grep -qE "^${key}=__CHANGE_ME__$" .env; then
    val="$(gen)"
    # python3 keeps the replacement byte-safe for special characters
    python3 - "$key" "$val" <<'PY'
import sys, pathlib
key, val = sys.argv[1], sys.argv[2]
p = pathlib.Path(".env")
lines = [f"{key}={val}\n" if l.startswith(key + "=") else l for l in p.read_text().splitlines(keepends=True)]
p.write_text("".join(lines))
PY
    echo "  ✓ ${key} kitöltve"
  else
    echo "  · ${key} már ki van töltve, kihagyva"
  fi
}

for k in MYSQL_ROOT_PASSWORD MYSQL_PASSWORD REDIS_PASSWORD; do fill "$k"; done
chmod 600 .env
echo "✓ .env kész (chmod 600)"
