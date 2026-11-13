# ADR 0003 — Redis as an object cache, not as a session store

- **Status:** accepted
- **Date:** 2026-11-12

## Context

WooCommerce is database-heavy: cart, catalog, and option lookups dominate the request time.
Redis is the standard object cache backend for WordPress.

## Decision

Run Redis on the internal network with `requirepass`, rename destructive commands
(`FLUSHALL`, `FLUSHDB`, `CONFIG`, `SHUTDOWN`), and use it **only** as a cache.

## Consequences

- Redis loss is a performance event, not a data-loss event — nothing authoritative lives there.
- The app cannot wipe the cache by accident: the command is renamed away.
- Sessions stay in WordPress; a cache flush does not log users out.

## Alternatives considered

- **APCu:** faster, but per-process — useless with several php-fpm workers.
- **Memcached:** no persistence, no password in older builds; Redis has a better security story.
