#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="/opt/mymanager/server"
SEED_ENV="$APP_ROOT/.env.seed"
PRODUCTION_ENV="$APP_ROOT/.env.production"

if [[ ! -f "$SEED_ENV" ]]; then
  echo "Missing $SEED_ENV" >&2
  exit 1
fi

sed -i 's/\r$//' "$SEED_ENV"
google_client_id="$(sed -n 's/^GOOGLE_CLIENT_ID=//p' "$SEED_ENV" | head -n 1)"
if [[ -z "$google_client_id" ]]; then
  echo "GOOGLE_CLIENT_ID is missing from the seed environment" >&2
  exit 1
fi

umask 077
mysql_password="$(openssl rand -hex 24)"
mysql_root_password="$(openssl rand -hex 32)"
jwt_secret="$(openssl rand -hex 64)"

cat >"$PRODUCTION_ENV" <<EOF
API_DOMAIN=api.mymanger.in
NODE_ENV=production
HOST=0.0.0.0
PORT=5000
FRONTEND_URL=https://mymanger.in,https://www.mymanger.in
GOOGLE_CLIENT_ID=$google_client_id
JWT_ACCESS_SECRET=$jwt_secret
JWT_ACCESS_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_DAYS=14
REFRESH_TOKEN_COOKIE_NAME=mm_refresh_token
MYSQL_DATABASE=mymanager
MYSQL_USER=mymanager
MYSQL_PASSWORD=$mysql_password
MYSQL_ROOT_PASSWORD=$mysql_root_password
EOF

chmod 600 "$PRODUCTION_ENV"
rm -f "$SEED_ENV"
echo "Production environment created with server-generated secrets."