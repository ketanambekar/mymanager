#!/usr/bin/env bash
set -euo pipefail

cd /opt/mymanager/server
docker compose --env-file .env.production -f compose.production.yml build --pull api
docker compose --env-file .env.production -f compose.production.yml up -d
docker compose --env-file .env.production -f compose.production.yml ps