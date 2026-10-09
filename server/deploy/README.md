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

## Release and Deploy

The backend version lives in `server/package.json` and follows semver; every change is recorded in [CHANGELOG.md](../CHANGELOG.md).

1. Bump the version from the repository root with `npm --prefix server run version:patch` (or `version:minor`/`version:major`), add the release to `CHANGELOG.md`, and commit.
2. Build the bundle from committed code on the workstation:

   ```powershell
   powershell -ExecutionPolicy Bypass -File server\deploy\package_release.ps1 -Tag
   git push origin server-v<version>
   ```

   The script refuses uncommitted `server/` changes and a version tag that already points at different code. It writes `mymanager-server-v<version>-<commit>.tar.gz` (in `%TEMP%` by default) with a `RELEASE_COMMIT` file, keeping LF line endings for Linux.
3. Transfer and extract the bundle into `/opt/mymanager/server`, preserving the server-owned `.env.production`:

   ```bash
   tar -xzf mymanager-server-v<version>-<commit>.tar.gz -C /opt/mymanager/server
   cd /opt/mymanager/server
   bash deploy/deploy.sh
   ```

`deploy.sh` reads the version and commit, builds the image tagged `mymanager-api:<version>`, and waits for `/health` to report the new build. It then appends the result to `/opt/mymanager/server/deployments.log`; if the new version never reports healthy, it fails and prints the API logs. The API image runs `prisma migrate deploy` before starting. Do not use `prisma db push` in production. Back up the database (`sudo bash deploy/backup_database.sh`) before releases with migrations.

## Which Version Is Running?

```bash
curl -s https://api.mymanger.in/health      # {"status":"ok","version":"1.1.0","commit":"<sha>","builtAt":"<utc>"}
curl -sI https://api.mymanger.in/health | grep -i x-api-version
cat /opt/mymanager/server/deployments.log   # deployment history
docker image ls mymanager-api               # images kept per version
```

To roll back, re-extract the previous bundle and run `deploy.sh`; `docker image prune` removes old images when disk space is needed. Rolling back code does not roll back migrations, so keep migrations additive.

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

### QR login retention (1.2.0+)

After deploying 1.2.0, install the supplied daily 02:30 UTC cron job:

```bash
cd /opt/mymanager/server
sudo install -m 644 -o root -g root deploy/auth_cleanup.cron /etc/cron.d/mymanager-auth-cleanup
sudo bash deploy/cleanup_auth.sh
```

The job appends output to `/var/log/mymanager-auth-cleanup.log` and records failures in syslog with tag `mymanager-auth-cleanup`; monitor these using the host's operations tooling. To invoke the container command directly:

```bash
cd /opt/mymanager/server
docker compose --env-file .env.production -f compose.production.yml exec -T api npm run cleanup:auth
```

The job deletes QR login requests only when they expired more than 24 hours ago, in batches of 1,000. It never deletes live challenges or user/device sessions. Packaging the code does not install the host scheduler; perform the installation step above.

The additive QR/device migration preserves existing refresh families. Old access tokens without device binding require one normal refresh; verify existing-cookie bootstrap and remote revocation after rollout. See the [QR/device contract](../../docs/ben/api-contracts/qr_sessions.md) for complete client checks.

## Security

- UFW allows only SSH, HTTP, HTTPS, and HTTP/3.
- Password and direct root SSH logins are disabled.
- Fail2ban and unattended upgrades are enabled.
- MySQL is available only on the internal Docker network.
- The API is bound to host loopback; Caddy is the public edge.
- Container logs rotate at 10 MB with three files per service.