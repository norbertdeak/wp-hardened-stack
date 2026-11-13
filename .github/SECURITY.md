# Security policy

## Reporting

Do not open a public issue for a vulnerability. Email the maintainer, or use GitHub's
private vulnerability reporting. You will get an answer within 72 hours.

## Supported versions

Only the latest tagged release is supported. Pins older than the security baseline in
`config/security-baseline.json` are refused by the build gate.

## Scope

In scope: the compose topology, nginx/php/redis/mariadb configuration, the version gate,
the hardening scripts.

Out of scope: vulnerabilities in WordPress core, plugins, or themes — report those upstream.
