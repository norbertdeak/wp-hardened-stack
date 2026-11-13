# Contributing

## Commit messages

Conventional Commits: `type(scope): subject`.

```
feat(nginx): add rate limit for wp-login
fix(compose): keep redis on the internal network
docs(adr): record the version-gate decision
test(gate): cover the below-baseline case
chore(deps): bump php to 8.3.14
```

Types: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`, `security`.
A `security:` commit must reference the control it changes in `docs/SECURITY.md`.

## Before opening a PR

```bash
make test    # unit tests + shell syntax
make lint    # shellcheck (if installed) + docker compose config
make gate    # the version gate must pass
```

## What gets rejected

- A new floating tag (`:latest`, `:stable`).
- A secret in any tracked file.
- A hardening change without a matching test in `tests/`.
- A comment that explains *what* the code does instead of *why*.
