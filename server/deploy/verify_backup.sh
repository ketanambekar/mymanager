#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="/opt/mymanager/server"
BACKUP_ROOT="/var/backups/mymanager"
RESTORE_DATABASE="mymanager_restore_check"
backup_file="${1:-$(find "$BACKUP_ROOT" -type f -name 'mymanager-*.sql.gz' | sort | tail -n 1)}"

if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
  echo "Backup file not found" >&2
  exit 1
fi

cd "$APP_ROOT"
compose=(docker compose --env-file .env.production -f compose.production.yml)

cleanup() {
  "${compose[@]}" exec -T db sh -c \
    'mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS mymanager_restore_check"' >/dev/null
}
trap cleanup EXIT

"${compose[@]}" exec -T db sh -c \
  'mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS mymanager_restore_check; CREATE DATABASE mymanager_restore_check CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"' >/dev/null

gzip -dc "$backup_file" | "${compose[@]}" exec -T db sh -c \
  'mysql -u root -p"$MYSQL_ROOT_PASSWORD" mymanager_restore_check'

migration_count="$("${compose[@]}" exec -T db sh -c \
  'mysql -N -u root -p"$MYSQL_ROOT_PASSWORD" mymanager_restore_check -e "SELECT COUNT(*) FROM _prisma_migrations WHERE finished_at IS NOT NULL"' 2>/dev/null)"

if [[ "$migration_count" -lt 4 ]]; then
  echo "Restore verification failed: expected at least 4 completed migrations" >&2
  exit 1
fi

echo "Backup restore verified with $migration_count completed migrations."