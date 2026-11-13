# Runbook

## First start

```bash
cp .env.example .env
make key
make gate          # must print "preflight rendben"
make up
make harden-wp
make health
```

## Daily

- `make health` — 6 checks, exits non-zero on the first failure.
- `docker compose ps` — every service `healthy`.

## Weekly

```bash
docker compose pull          # new patch images (pins are still exact)
make gate                    # re-run the gate after a pull
docker compose up -d
docker image prune -f
```

## Backup / restore

```bash
make backup                                  # → backups/<stamp>/{db.sql.gz,uploads.tar.gz}
# restore:
gunzip -c backups/<stamp>/db.sql.gz | docker compose exec -T mariadb \
  mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
docker run --rm -v "${COMPOSE_PROJECT_NAME}_wordpress_data:/data" \
  -v "$PWD/backups/<stamp>:/backup" alpine \
  tar -xzf /backup/uploads.tar.gz -C /data
```

**A backup you have never restored is not a backup.** Restore into a scratch stack once a quarter.

## Rotate a secret

1. Generate a new value (`openssl rand -base64 32`).
2. Update `.env`.
3. `docker compose up -d <service>` — only the dependent service restarts.
4. For MySQL, change the password inside the DB first, then the `.env`, then restart.

## Incident: suspected compromise

1. **Contain, don't clean.** `docker compose stop nginx`.
2. Snapshot: `docker commit` the app container, copy `db_data` — evidence before repair.
3. Rotate: DB password, Redis password, WordPress salts, all admin passwords, payment keys.
4. Rebuild from a clean image; do not `docker compose up` the compromised one.
5. Check `docker compose logs --since 72h` and the nginx access log for the entry vector.
6. Write it down: what happened, what was the vector, what control failed.

## Common failures

| Symptom | Cause | Fix |
|---|---|---|
| `502` from nginx | php-fpm not up or wrong socket | `docker compose logs wordpress` |
| `Error establishing a database connection` | wrong `.env` password or DB not ready | `docker compose ps mariadb` |
| Gate exits 1 | a pin is below baseline | `make gate WRITE=1` then rebuild |
| Admin locked out | salts rotated | restore the previous `wp-config.php` from backup |
