# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · SemVer.

## [0.1.0] — 2026-11-12

### Added
- Docker Compose stack: nginx, php-fpm (WordPress + WooCommerce), MariaDB, Redis.
- Split network topology (`edge` / `back`, the latter `internal: true`).
- Hardened nginx: no version banner, CSP, HSTS, login rate limit, XML-RPC and uploads denied.
- Hardened PHP: `open_basedir`, disabled functions, secure session cookies, OPcache.
- Hardened Redis: password, renamed destructive commands, LRU eviction.
- **Version gate** (`scripts/lib/version_gate.py`) with an offline baseline and endoflife.date lookup.
- Idempotent WordPress hardening script.
- Backup and restore procedure, healthchecks, runbook.
- Tests asserting the hardening flags are present in the actual config files.
- CI: unit tests, CodeQL, Dependabot, issue/PR templates.

[0.1.0]: https://github.com/norbertdeak/wp-hardened-stack/releases/tag/v0.1.0
