# Production Operations

## Host

- Provider: Hetzner
- Server: `ubuntu-2gb-hel1-1` (`#168110502`)
- IPv4: `204.168.227.167`
- IPv6: `2a01:4f9:c013:f41::1`
- Application root: `/opt/mymanager/server`
- SSH user: `mymanager` (direct root login is disabled)

Connect from the deployment workstation:

```powershell
ssh -i "$HOME\.ssh\mymanger_hetzner_ed25519" mymanager@204.168.227.167
```

Never copy or disclose the private SSH key or `/opt/mymanager/server/.env.production`.

## DNS Required

Create these records before expecting HTTPS:

| Type | Name | Value |
|---|---|---|
| `A` | `api` | `204.168.227.167` |
| `AAAA` | `api` | `2a01:4f9:c013:f41::1` |

Use DNS-only mode until Caddy obtains the first certificate. Caddy automatically provisions and renews TLS for `api.mymanger.in`.

The frontend production variable is:

```text
VITE_API_BASE_URL=https://api.mymanger.in/api/v1
```

## Deploy

Transfer a clean `server/` source bundle to `/opt/mymanager/server`, preserving the server-owned `.env.production`, then run:

```bash
cd /opt/mymanager/server
bash deploy/deploy.sh
```

The API image runs `prisma migrate deploy` before starting. Do not use `prisma db push` in production.

## Operations

```bash
cd /opt/mymanager/server

# Service state
docker compose --env-file .env.production -f compose.production.yml ps

# API logs
docker compose --env-file .env.production -f compose.production.yml logs --tail=200 api

# Health
curl --fail http://127.0.0.1:5000/health

# Database migration state
docker compose --env-file .env.production -f compose.production.yml exec -T api npx prisma migrate status

# Manual backup and restore verification
sudo bash deploy/backup_database.sh
sudo bash deploy/verify_backup.sh
```

Daily compressed MySQL backups run at 02:15 UTC and are retained for 14 days in `/var/backups/mymanager`. Hetzner automated backups or another off-server destination must also be enabled; same-disk backups do not protect against server loss.

## Security

- UFW allows only SSH, HTTP, HTTPS, and HTTP/3.
- Password and direct root SSH logins are disabled.
- Fail2ban and unattended upgrades are enabled.
- MySQL is available only on the internal Docker network.
- The API is bound to host loopback; Caddy is the public edge.
- Container logs rotate at 10 MB with three files per service.