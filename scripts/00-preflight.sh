#!/usr/bin/env bash
# Preflight: environment checks + the security version gate.
# Fails closed — a vulnerable pin stops the build.
set -Eeuo pipefail

cd "$(dirname "$0")/.."
WRITE_FLAG=""
[[ "${WRITE:-0}" == "1" ]] && WRITE_FLAG="--write"

echo "== askme/wp-hardened-stack preflight =="

# 1. Toolchain
for cmd in docker python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "✗ hiányzó eszköz: $cmd" >&2
    exit 2
  fi
done
docker compose version >/dev/null 2>&1 || { echo "✗ docker compose plugin kell" >&2; exit 2; }
echo "  ✓ docker $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo '?'), python $(python3 -V | cut -d' ' -f2)"

# 2. Secrets present?
if [[ ! -f .env ]]; then
  echo "✗ nincs .env — futtasd: cp .env.example .env && make key" >&2
  exit 2
fi
if grep -q '__CHANGE_ME__' .env; then
  echo "✗ a .env-ben placeholder jelszó van — futtasd: make key" >&2
  exit 2
fi

# 3. Version gate (the interesting part)
echo
echo "-- verzió-kapu (security baseline + endoflife.date) --"
python3 scripts/lib/version_gate.py $WRITE_FLAG

# 4. Compose sanity (no interpolation errors, no floating tags)
if ! grep -qE 'image:.*:latest' docker-compose.yml; then
  echo "  ✓ nincs :latest tag a compose-ban"
else
  echo "✗ :latest tag a compose-ban — pinneld a verziót" >&2
  exit 1
fi

# 5. Sync the pins into .env — compose interpolates from .env, the gate edits config/versions.env
python3 - <<'PY'
import pathlib, re
pins = {}
for line in pathlib.Path("config/versions.env").read_text().splitlines():
    if "=" in line and not line.startswith("#"):
        k, v = line.split("=", 1); pins[k.strip()] = v.strip()
env = pathlib.Path(".env")
lines = env.read_text().splitlines(keepends=True)
out, seen = [], set()
for line in lines:
    key = line.split("=", 1)[0].strip() if "=" in line else ""
    if key in pins:
        out.append(f"{key}={pins[key]}
"); seen.add(key)
    else:
        out.append(line)
for k, v in pins.items():
    if k not in seen:
        out.append(f"{k}={v}
")
env.write_text("".join(out))
print("  ✓ verziók szinkronizálva a .env-be")
PY

echo
echo "✓ preflight rendben"
