# Ben Learning Log

Persistent, project-specific memory for Ben. Keep entries factual, concise, and date-stamped with ISO dates. Append entries chronologically. Keep implementation guidance in `backend-guidelines.md`; this log records durable decisions and how guidance evolves.

## Rules and Decisions

### 2026-09-30

- The owner requested a Node.js backend specialist named Ben, codename MARK-02, with DOB 2026-09-30.
- Follow Adam's project habits where relevant: separate feature responsibilities, keep documentation in root `docs/`, finish implementation requests, wait for command completion, and report verification accurately.
- The repository currently has no backend package. Do not assume a framework or mix backend code into `client/`; inspect the repo and choose a stack deliberately when backend work is requested.
- Record future durable backend instructions and project facts here by date, with distinct lists for rules/decisions, meaningful mistakes/corrections, and verified achievements.
- The owner wants Postman collection creation and maintenance included in Ben's capabilities. Collections should be reusable across environments, with dynamic base URLs, auth tokens, and other varying values, and must not contain real credentials or hard-coded environment-specific URLs.
- Whenever Ben creates or changes an API (and its Postman collection when in scope), he must provide/update a per-feature API contract with explicit frontend binding guidance for Adam. Adam must follow that contract and ask instead of guessing if it is missing or ambiguous.
- API handoffs must include both a React integration section for Adam and a Flutter/GetX/Dio integration section for Dartji, with native Google audience and cookie/session behavior explicitly verified.
- The owner approved building the backend as an independent root `server/` package and requested that every completed frontend Phase 1 flow become API-backed, with a reusable Postman collection and a dedicated Adam handoff folder.
- The established backend stack is Express 5, TypeScript, Prisma, and MySQL. Authentication is Google-only with short-lived access tokens and rotating, hashed refresh sessions.

### 2026-10-05

- The owner approved overdue-task Skip/Miss: add `SKIPPED` and `MISSED` task states with versioned `POST /tasks/:taskId/skip` and `/miss`. Skip is for overdue recurring tasks only; Miss is for any overdue task (terminal for one-time tasks). Neither requires subtasks to be complete. Both are idempotent and continue the recurrence series. Skipped/missed tasks are neither open nor completed in filters and aggregates.
- Ben's implementation choices: skipped tasks are excluded from completion-rate and project-progress denominators while missed tasks lower them. Superseded by the owner: skipped/missed tasks are terminal and cannot be reopened (`409 TASK_NOT_REOPENABLE`).
- Owner rule: Miss also requires a free-text reason explaining why it was missed (same 1–200 character rule as Skip, stored in `closeReason`). Clients offer five miss presets: Forgot about it, Ran out of time, Something urgent came up, Low energy or motivation, Blocked or waiting on someone.
- Skip means "I chose not to do this occurrence" and requires a free-text reason (1–200 characters, stored in `task.closeReason`). Clients offer five preset reasons as suggestions. Closing an overdue recurring occurrence must never touch or duplicate an already-materialized next occurrence.
- The owner requires visible backend versioning so it is clear which code is deployed. Adopted semver in `server/package.json` (independent of the client), `server/CHANGELOG.md`, `server-v<version>` tags, commit-stamped release bundles, and version metadata on `/health` and `x-api-version`. Skip/Miss ships as 1.1.0; the previously deployed code is recorded as 1.0.0.

### 2026-10-09

- The owner requested QR scanning or numeric-code login to another browser/device from an already authenticated device, plus device management with active-session count, sign-in/last-use timestamps, and per-session remote logout. Adam owns the login-page and signed-in device/settings UI integration.
- QR login uses explicit authenticated approval, five-minute expiry, requester-only poll/claim secrets, and atomic one-time consumption. Stable device sessions preserve refresh-family identity; revocation is enforced on subsequent protected requests, including existing access tokens.

## Mistakes and Corrections

### 2026-09-30

- An initial generated migration assumed an empty database, but the legacy MySQL database contained user/project/task data. It was discarded before deployment and replaced with a forward, data-preserving migration tested against a populated clone and protected by a full database backup.
- The first malformed-JSON smoke test returned a generic 500 because request IDs were assigned after body parsing. Request correlation now runs before parsing, and malformed JSON returns a consistent 400 error.
- The inherited migrations created mixed-case MySQL tables but referenced them in lowercase; this passed on Windows and failed on Linux. Production MySQL now initializes with `lower_case_table_names=1`, and the empty failed production volume was recreated before any user data existed.
- Production authentication rate limiting initially saw Caddy as the shared client IP and used one quota for Google login and refresh failures. Express now trusts exactly one proxy hop, with independent 30-per-15-minute login and 60-per-15-minute refresh buckets.

### 2026-10-05

- On Windows, `core.autocrlf=true` made `git archive` emit CRLF shell scripts, which would fail under bash on the Linux host. Release bundles are now built with `git -c core.autocrlf=false archive`; verified zero carriage returns in bundled `.sh`, Dockerfile, Caddyfile, and compose files.

## Verified Achievements

### 2026-09-30

- Created the workspace-specific Ben agent and initial backend guidelines based on the repository's actual frontend-only state.
- Built the independent `server/` package with Google authentication, workspaces/preferences, hierarchical projects, task/subtask CRUD, optimistic concurrency, recurrence, completion rules, dashboard aggregation, migrations, and consistent security/error middleware.
- Migrated the local MySQL database while preserving 2 users, 2 projects, 5 tasks, and 6 subtasks; retained backup database `mymanager_backup_20260930132649` and verified migration status is current.
- Added feature contracts under `docs/ben/api-contracts/` and a parameterized Phase 1 Postman collection under `server/postman/`.
- Added Flutter/GetX/Dio integration guidance for Dartji to the auth, dashboard, preferences, projects, and tasks API contracts; native auth still requires mobile-specific Google audience and cookie-flow verification before client implementation.
- Verified strict TypeScript build, six recurrence tests, valid Postman JSON, zero production dependency vulnerabilities, health/auth error boundaries, and an authenticated tenant-scoped dashboard response.
- Provisioned Hetzner server `#168110502` with Docker Compose, Caddy, MySQL, UFW, fail2ban, unattended upgrades, 2 GB swap, a sudo-enabled `mymanager` deployment account, disabled direct root/password SSH, private database/API ports, resource limits, and rotating container logs.
- Deployed the production stack successfully with healthy MySQL and API containers and all four migrations current. Installed daily 02:15 UTC database backups with 14-day retention and verified a full restore containing four completed migrations.
- Public DNS and Let’s Encrypt HTTPS are active for `api.mymanger.in`; the production health endpoint is reachable through Caddy.
- Deployed and verified the proxy-aware authentication rate-limit correction: all eight server tests, TypeScript build, patch checks, and production dependency audit passed; production HTTPS returned `200`, login advertised limit 30, refresh advertised limit 60, and the running image contained the one-hop proxy configuration.

### 2026-10-05

- Implemented task Skip/Miss with additive migration `20261005130000_task_skip_miss_states` (enum values + nullable `closedAt`). Verified strict build, 15 unit tests, and a disposable-MySQL integration run covering state transitions, recurrence continuation without duplicates, idempotent retries, concurrent skips, version conflicts, guards, list filters, and dashboard/project aggregates. Applied the migration locally; production deployment is pending.
- Added a required skip reason via migration `20261005133000_task_close_reason`. Verified 16 unit tests, a strict build, and a disposable-MySQL scenario run: a daily task due yesterday showed both yesterday's and today's occurrences, and missing or skipping yesterday left today's occurrence open with no duplicate. Reopen cleared the reason.
- Added backend release versioning (v1.1.0): the compiled server reported version, commit, and build time on `/health`, the `x-api-version` header, and the startup log. 17 tests and a strict typecheck passed. The packaging script rejected uncommitted changes and stamped `RELEASE_COMMIT`, and `deploy.sh` passed `bash -n` with correct version parsing.- Made the Miss reason required (same schema as Skip). Verified 18 unit tests, a strict typecheck, and a disposable-MySQL HTTP run: a miss without a reason returned 400, a miss with a reason stored `closeReason`, a retry kept the original reason, and reopening a missed task returned 409 `TASK_NOT_REOPENABLE`.
- Deployed backend v1.1.0 (commit `f8d566a`, tag `server-v1.1.0`) to production after a fresh database backup. Both new migrations were applied, and the public `/health` reported 1.1.0 with commit and build time. Production CORS for `https://mymanger.in` was unchanged, and the client's Vite dev proxy on `localhost:3000` reached the production API.
- Owner request: the local client must be able to use the production API. Decision: use the client's Vite dev proxy (`API_PROXY_TARGET`) instead of adding `localhost` origins to production CORS. The `SameSite=Lax` refresh cookie would not be sent cross-site anyway.

### 2026-10-09

- Implemented backend 1.2.0 QR/code login, stable device sessions, account-scoped remote revocation, atomic refresh rotation, and bounded expired-challenge cleanup. Verified strict TypeScript build, 21 unit/regression tests, and disposable-MySQL scenarios covering populated migration preservation, Google-response compatibility, HTTP login/claim, expiry/deny/cancel, competing approvals/claims, refresh reuse/concurrency, disabled/revoked approvers, activity/logout, rate/origin/validation boundaries, and retention cleanup. The dedicated test database was removed; production deployment and native cookie verification are not included.
- Deployed backend 1.2.0 from commit `6e586e990638` (tag `server-v1.2.0`) after creating and restoring a production backup with six completed migrations. Verified healthy API/MySQL containers, all seven migrations current, public HTTPS release metadata, QR create/status/cancel, rejection of premature claims and unauthenticated approval/device requests, and untrusted-Origin rejection. Installed the daily 02:30 UTC cleanup cron and successfully ran its wrapper. Backend and handoff changes were pushed to `features/enhancements` and fast-forward merged/pushed to `main`; concurrent uncommitted frontend changes were preserved. Native cookie verification and real-user browser acceptance remain client work.
