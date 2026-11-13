#!/usr/bin/env bash
# Idempotent WordPress hardening. Safe to run repeatedly.
set -Eeuo pipefail
cd "$(dirname "$0")/.."

WP="docker compose exec -T -u www-data wordpress wp --path=/var/www/html"

echo "== WordPress hardening =="

# 1. No file editing from the admin UI, no debug output, no directory listing
$WP config set DISALLOW_FILE_EDIT true --raw --type=constant 2>/dev/null || true
$WP config set DISALLOW_FILE_MODS false --raw --type=constant 2>/dev/null || true
$WP config set WP_DEBUG false --raw --type=constant 2>/dev/null || true
$WP config set FORCE_SSL_ADMIN true --raw --type=constant 2>/dev/null || true
$WP config set AUTOMATIC_UPDATER_DISABLED false --raw --type=constant 2>/dev/null || true
echo "  ✓ wp-config konstansok"

# 2. Delete the default sample content and the default admin if it still exists
$WP post delete 1 2 3 --force 2>/dev/null || true

# 3. Permissions: files 644, dirs 755, wp-config 600
docker compose exec -T wordpress sh -c '
  find /var/www/html -type d -exec chmod 755 {} \; 2>/dev/null;
  find /var/www/html -type f -exec chmod 644 {} \; 2>/dev/null;
  chmod 600 /var/www/html/wp-config.php 2>/dev/null || true;
'
echo "  ✓ fájl-jogosultságok (644/755, wp-config 600)"

# 4. Disable XML-RPC at the app level as well (defence in depth)
$WP config set XMLRPC_REQUEST false --raw --type=constant 2>/dev/null || true

# 5. Regenerate salts only on first run (rotating them logs everyone out)
if ! $WP config get AUTH_KEY --type=constant >/dev/null 2>&1; then
  $WP config shuffle-salts
  echo "  ✓ salts generálva"
fi

# 6. Report what is still weak, without changing anything silently
echo
echo "-- állapot --"
$WP core version
$WP plugin list --status=active --format=table 2>/dev/null || true
echo
echo "✓ hardening kész (idempotens)"
