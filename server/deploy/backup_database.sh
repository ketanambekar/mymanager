#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="/opt/mymanager/server"
BACKUP_ROOT="/var/backups/mymanager"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

install -d -m 700 "$BACKUP_ROOT"
cd "$APP_ROOT"

docker compose --env-file .env.production -f compose.production.yml exec -T db \
  sh -c 'exec mysqldump --single-transaction --quick --lock-tables=false -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' \
  | gzip -9 >"$BACKUP_ROOT/mymanager-$STAMP.sql.gz"

find "$BACKUP_ROOT" -type f -name 'mymanager-*.sql.gz' -mtime +14 -delete