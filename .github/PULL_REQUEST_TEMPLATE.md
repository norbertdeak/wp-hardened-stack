## What changed

<!-- one paragraph, in the imperative -->

## Why

<!-- the problem, not the solution -->

## Security impact

- [ ] No secret added to a tracked file
- [ ] No floating image tag added
- [ ] Hardening change has a matching test in `tests/`
- [ ] `docs/SECURITY.md` updated if a control changed

## How it was verified

```
make test
make gate
make health
```

## Rollback

<!-- how to undo this in one command -->
