# ADR 0001 — Docker Compose instead of Kubernetes

- **Status:** accepted
- **Date:** 2026-11-12

## Context

The target is a single VPS running one WordPress site per client, operated by one person.
Kubernetes would add a control plane, an ingress controller, and a new failure domain.

## Decision

Use Docker Compose with pinned images and an explicit network split (`edge` / `back`).

## Consequences

- One command to start, one to stop, logs in one place. An operator can reason about it at 2 a.m.
- No self-healing scheduler: `restart: unless-stopped` plus healthchecks cover the common cases.
- Scaling out means a second host and a load balancer, not a `replicas:` line. That is acceptable
  for this workload.

## Alternatives considered

- **Kubernetes (k3s):** rejected — operational overhead exceeds the value for one site.
- **Bare metal + systemd:** rejected — no image pinning, no reproducible rollback.
- **Managed WordPress hosting:** rejected — the point is to own the stack and the hardening.
