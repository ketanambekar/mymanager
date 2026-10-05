#!/usr/bin/env bash
set -euo pipefail

cd /opt/mymanager/server

APP_VERSION="$(sed -n 's/^  "version": "\([^"]*\)",$/\1/p' package.json | head -n 1)"
if [[ -z "$APP_VERSION" ]]; then
  echo "Could not read the version from package.json" >&2
  exit 1
fi

GIT_COMMIT="unknown"
if [[ -f RELEASE_COMMIT ]]; then
  GIT_COMMIT="$(tr -d '[:space:]' < RELEASE_COMMIT)"
else
  echo "WARNING: RELEASE_COMMIT is missing; create the bundle with deploy/package_release.ps1 so the commit is traceable." >&2
fi
BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
export APP_VERSION GIT_COMMIT BUILD_TIME

echo "Deploying MyManger API v${APP_VERSION} (commit ${GIT_COMMIT:0:12})"

compose=(docker compose --env-file .env.production -f compose.production.yml)
"${compose[@]}" build --pull api
"${compose[@]}" up -d
"${compose[@]}" ps

# Wait until the replacement container reports the version that was just built.
expected="\"version\":\"${APP_VERSION}\""
for _ in $(seq 1 45); do
  health="$(curl -fsS http://127.0.0.1:5000/health 2>/dev/null || true)"
  if [[ "$health" == *"$expected"* && "$health" == *"$BUILD_TIME"* ]]; then
    echo "${BUILD_TIME} v${APP_VERSION} commit=${GIT_COMMIT} image=mymanager-api:${APP_VERSION}" >> deployments.log
    echo "Live: ${health}"
    exit 0
  fi
  sleep 2
done

echo "Deployment check failed: /health did not report v${APP_VERSION} built at ${BUILD_TIME}." >&2
"${compose[@]}" logs --tail=50 api >&2
exit 1
