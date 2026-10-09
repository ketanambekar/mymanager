#!/usr/bin/env bash
set -euo pipefail

trap 'logger -p user.err -t mymanager-auth-cleanup "QR challenge cleanup failed"; exit 1' ERR
cd /opt/mymanager/server
docker compose --env-file .env.production -f compose.production.yml exec -T api npm run cleanup:auth
