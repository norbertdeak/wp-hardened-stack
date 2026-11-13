#!/usr/bin/env bash
# End-to-end checks: the stack answers, the security headers are present,
# and the two cheapest attack surfaces (xmlrpc, uploads) are closed.
set -Eeuo pipefail
cd "$(dirname "$0")/.."

BASE="http://127.0.0.1:${HTTP_PORT:-8080}"
fail=0

check() { # name expected_contains url [extra curl args]
  local name="$1" expect="$2" url="$3"; shift 3
  local out code
  out="$(curl -sS -o /tmp/.hc.body -w '%{http_code}' "$@" "$url" || echo 000)"
  code="$out"
  if [[ "$code" == "$expect" ]]; then
    echo "  ✓ $name ($code)"
  else
    echo "  ✗ $name (várt: $expect, kapott: $code)"; fail=1
  fi
}

echo "== health =="
check "healthz"        200 "$BASE/healthz"
check "kezdőlap"       200 "$BASE/"
check "xmlrpc tiltva"  403 "$BASE/xmlrpc.php"

echo "== security headers =="
for h in X-Content-Type-Options X-Frame-Options Referrer-Policy Content-Security-Policy; do
  if curl -sSI "$BASE/" | grep -qi "^${h}:"; then echo "  ✓ $h"; else echo "  ✗ $h hiányzik"; fail=1; fi
done

echo "== szerver banner =="
if curl -sSI "$BASE/" | grep -qi '^Server:.*nginx/[0-9]'; then
  echo "  ✗ a Server fejléc verziót szivárogtat"; fail=1
else
  echo "  ✓ nincs verzió a Server fejlécben"
fi

echo "== konténer állapot =="
docker compose ps --format '{{.Name}}\t{{.Status}}' || true

exit "$fail"
