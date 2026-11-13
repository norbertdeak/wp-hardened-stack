# Security controls

Every control below is enforced by a file in this repository and asserted by a test.
If a control is only in the documentation, it does not exist.

## Container / Docker

| Control | Where | Test |
|---|---|---|
| `no-new-privileges` on all services | `docker-compose.yml` | `test_compose_hardening` |
| `cap_drop: ALL` (with a minimal add-back for nginx) | `docker-compose.yml` | idem |
| Non-root runtime for WordPress | `Dockerfile.wordpress` (`USER www-data`) | manual |
| Read-only root filesystem (nginx, redis) | `docker-compose.yml` | idem |
| Internal-only database network | `networks.back.internal: true` | idem |
| Healthchecks on every service | `docker-compose.yml` | `make health` |

## nginx

| Control | Value |
|---|---|
| Version banner | `server_tokens off` + no `Server` version |
| TLS | 1.2 / 1.3 only (prod overlay) |
| HSTS | `max-age=31536000` (prod overlay) |
| CSP | `default-src 'self'`, no third-party scripts |
| Login brute force | `limit_req zone=login rate=5r/m burst=3` |
| XML-RPC | `deny all` |
| PHP in uploads | `deny all` |
| Dotfiles / `.env` / `.sql` | `deny all` |
| Author enumeration | `?author=N` redirected |

## PHP

| Control | Value |
|---|---|
| `expose_php` | Off |
| `display_errors` | Off, logged to stderr |
| `allow_url_include` / `allow_url_fopen` | Off |
| `open_basedir` | `/var/www/html:/tmp` |
| Dangerous functions | `exec, shell_exec, system, proc_open, …` disabled |
| Session cookies | `HttpOnly`, `Secure`, `SameSite=Lax`, strict mode |

## WordPress

| Control | How |
|---|---|
| File editor disabled | `DISALLOW_FILE_EDIT` |
| Debug off | `WP_DEBUG=false` |
| Admin over TLS | `FORCE_SSL_ADMIN` |
| Permissions | dirs 755, files 644, `wp-config.php` 600 |
| Default content | deleted |
| Salts | generated on first run, rotated deliberately |
| Object cache | Redis with password, dangerous commands renamed |

## Secrets

- `.env` is git-ignored; `.env.example` contains names only.
- `make key` writes secrets without echoing them.
- Redis and MySQL passwords are generated with `openssl rand`, 32 chars.
- No credential ever appears in a compose file or a Dockerfile.

## What this stack does NOT do

- It does not patch WordPress plugins for you — that is `make` + a maintenance window.
- It does not provide WAF rules; put Cloudflare or an nginx `njs` rule set in front if you need them.
- It does not encrypt the database volume at rest; use an encrypted block device if that is a requirement.
