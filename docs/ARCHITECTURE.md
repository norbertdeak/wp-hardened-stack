# Architecture

```
                    ┌──────────────┐
   :8080/:443  ───► │    nginx     │  TLS, headers, rate limits, static
                    └──────┬───────┘
                           │ fastcgi 9000 (internal)
                    ┌──────▼───────┐        ┌──────────────┐
                    │  php-fpm     │◄──────►│    redis     │  object cache
                    │ wordpress    │        └──────────────┘
                    └──────┬───────┘
                           │ 3306 (internal)
                    ┌──────▼───────┐
                    │   mariadb    │  db_data volume
                    └──────────────┘

networks: edge (nginx only) · back (internal, no route out)
```

## Why three layers and not one

A single `wordpress:latest` container with an Apache inside is smaller to write and much
harder to reason about. Splitting the edge (nginx) from the runtime (php-fpm) buys three
things that matter in an incident:

1. **The PHP process never sees a socket.** If it is compromised, there is no port to bind.
2. **Rate limits and header policy live outside the app.** A plugin update cannot silently
   remove HSTS.
3. **The database is not reachable from the edge network.** `back` is declared `internal: true`,
   so there is no egress path at all.

## Data flow

1. Request hits nginx on `edge`.
2. Static files are served from the read-only WordPress volume.
3. `*.php` goes to php-fpm over the internal `back` network.
4. WP reads/writes MariaDB; the object cache is Redis with `requirepass`.
5. Responses pass back through nginx, which appends the security headers.

## Volumes

| Volume | Content | Backup |
|---|---|---|
| `wordpress_data` | core, plugins, uploads | uploads only (`scripts/backup.sh`) |
| `db_data` | MySQL data dir | `mariadb-dump` |
| `redis_data` | cache persistence | not backed up (it is a cache) |

## Ports

Only nginx publishes. Every other service is reachable only on the internal network.
