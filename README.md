# wp-hardened-stack

Production-shaped WordPress + WooCommerce stack in Docker: nginx, PHP-FPM, MariaDB, Redis,
and a **version gate** that refuses to ship a known-vulnerable runtime.

> This is a reference skeleton, not a live deployment. Every decision below is written down
> in `docs/` and `docs/ADR/` — because a stack you cannot explain is a stack you cannot defend.

## What is in the box

| Layer | Choice | Why |
|---|---|---|
| Edge | nginx (TLS 1.2/1.3, HSTS, CSP, rate limits) | small, auditable, no runtime |
| App | PHP-FPM 8.3, WordPress + WooCommerce | pinned to a **patched** patch level |
| Data | MariaDB 11.4 LTS | LTS line, `local-infile=0` |
| Cache | Redis 7.4 + `redis-cache` object cache | fewer DB hits, `requirepass` |
| Runtime | Docker Compose, non-root, `cap_drop: ALL`, `no-new-privileges` | blast radius |

## Quick start

```bash
cp .env.example .env
make key            # generate secrets into .env (never committed)
make gate           # version gate: checks pinned runtimes against security baseline
make up             # build + start
make harden-wp      # apply WordPress hardening (idempotent)
make health         # end-to-end checks
```

`make gate` is the interesting one: it compares the pinned versions in `config/versions.env`
against a security baseline and, when a pin is behind, **rewrites the pin to the patched
release** before anything is built.

## Principles

1. **Pin, then verify.** Floating tags (`php:latest`) are how a Tuesday deploy becomes an outage.
2. **Fail closed.** The version gate exits non-zero; the build does not continue.
3. **Least privilege everywhere.** Container user, DB user, filesystem, network, Redis command set.
4. **Secrets never in git.** `.env` is ignored, `.env.example` carries only names.
5. **Every control is testable.** `make test` asserts the hardening flags are actually present.

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — components, data flow, ports
- [`docs/SECURITY.md`](docs/SECURITY.md) — the control list, mapped to the layer
- [`docs/THREAT-MODEL.md`](docs/THREAT-MODEL.md) — what we defend against, and what we don't
- [`docs/RUNBOOK.md`](docs/RUNBOOK.md) — start, backup, restore, rotate, incident
- [`docs/ADR/`](docs/ADR/) — the decisions and the alternatives that lost

## License

MIT
