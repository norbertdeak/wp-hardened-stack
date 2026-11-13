#!/usr/bin/env bash
# Dump the database and archive uploads. Keeps the last 7 by default.
set -Eeuo pipefail
cd "$(dirname "$0")/.."

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="backups/${STAMP}"
mkdir -p "$OUT"

set -a; source .env; set +a

echo "→ adatbázis dump"
docker compose exec -T mariadb \
  mariadb-dump --single-transaction --quick --routines --triggers \
  -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" | gzip -9 > "$OUT/db.sql.gz"

echo "→ feltöltések"
docker run --rm -v "${COMPOSE_PROJECT_NAME}_wordpress_data:/data:ro" -v "$PWD/$OUT:/backup" alpine \
  tar -czf /backup/uploads.tar.gz -C /data wp-content/uploads 2>/dev/null || true

echo "→ régi mentések takarítása (7 megtartása)"
ls -1dt backups/*/ 2>/dev/null | tail -n +8 | xargs -r rm -rf

du -sh "$OUT"/* 2>/dev/null || true
echo "✓ mentés: $OUT"
