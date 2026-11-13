# Threat model

Scope: a single-host WordPress + WooCommerce deployment behind nginx, operated by one
person. Out of scope: multi-tenant hosting, PCI DSS certification, nation-state adversaries.

## Assets

1. Customer orders and personal data (GDPR-relevant).
2. Admin credentials and session cookies.
3. Payment provider API keys (stored by the gateway plugin, not here).

## Adversaries

| Adversary | Capability | Motivation |
|---|---|---|
| Opportunistic scanner | Automated probes for known plugin CVEs, `xmlrpc.php`, `?author=` | Botnet, spam, SEO injection |
| Credential stuffer | Leaked password lists against `wp-login.php` | Account takeover |
| Malicious plugin | Code inside the app | Data exfiltration |
| Insider / mistake | Operator typo, `chmod 777`, a debug flag left on | Outage, leak |

## Threats and mitigations

| # | Threat | Mitigation | Residual risk |
|---|---|---|---|
| T1 | Brute force on `wp-login.php` | Rate limit 5/min, strong passwords, 2FA plugin recommended | Slow distributed attempts |
| T2 | Plugin CVE exploited | Pinned versions, Dependabot alerts, update runbook | Zero-day window |
| T3 | PHP shell uploaded via a plugin | PHP execution denied in `uploads/`, `disable_functions` | File read within docroot |
| T4 | DB exposed to the internet | `back` network is `internal: true`, no published port | Host-level compromise |
| T5 | Redis wiped / poisoned | `requirepass`, `FLUSHALL` renamed away, internal network | App-level cache poisoning |
| T6 | Secrets leaked in git | `.env` ignored, `.env.example` names only, `make key` | Operator pasting a secret into an issue |
| T7 | Session hijack | `HttpOnly`+`Secure`+`SameSite`, strict mode, TLS-only admin | XSS in a plugin |
| T8 | Version drift to a vulnerable patch | Version gate fails the build | Gate bypassed with `--offline` |

## Assumptions

- The host itself is patched and firewalled; this stack assumes a trustworthy kernel.
- Backups are stored off-host and tested; an untested backup is a rumour.
- The operator reads `docs/RUNBOOK.md` before the first incident, not during it.
