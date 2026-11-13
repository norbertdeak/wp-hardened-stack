# ADR 0002 — Pin exact versions, and gate them before build

- **Status:** accepted
- **Date:** 2026-11-12

## Context

Floating tags (`php:latest`) silently change the runtime. Pinning protects reproducibility but
can freeze a vulnerable version. Both failure modes are real: one causes surprise outages, the
other causes avoidable exposure.

## Decision

Pin a version in `config/versions.env`, and run a **version gate** before every build that:

1. compares the pin against `config/security-baseline.json` (offline truth), and
2. when the network is available, asks endoflife.date for the newest patch in that cycle,
3. rewrites the pin when it is behind, and **fails the build** if it cannot.

## Consequences

- A build never starts on a known-vulnerable pin.
- The decision is data, not a comment: the baseline is a JSON file under version control.
- The gate has unit tests; it is code, not a checklist.

## Alternatives considered

- **Renovate/Dependabot only:** good, but they open PRs asynchronously — they do not stop a
  `docker compose up` on a Friday afternoon.
- **`latest` + watchtower:** rejected — unreviewed automatic upgrades on a production site.
