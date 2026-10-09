# MyManger API Changelog

All notable backend changes are recorded here. The version in `package.json` is the single source of truth and follows [Semantic Versioning](https://semver.org/):

- **Major**: breaking change for existing clients (removed/renamed endpoint or field, changed meaning that breaks a released client).
- **Minor**: new endpoint, field, state, or migration that existing clients can tolerate.
- **Patch**: bug fix, security fix, or internal change with no contract change.

Each deployed release is tagged `server-v<version>`. Check the running version with `GET /health` or the `x-api-version` response header.

## 1.2.0 - 2026-10-09

### Added

- Five-minute, one-use QR/numeric-code login challenges with authenticated lookup and explicit approval/denial, requester-only polling/claiming/cancellation, hashed secrets, and attempt limits.
- Stable device sessions with active count, browser/app label, sign-in time, last API activity, refresh expiry, current-device indication, and owner-scoped remote logout.
- Daily `cleanup:auth` command for challenges expired more than 24 hours ago.
- Production cleanup wrapper and daily cron definition with explicit failure logging.
- QR/device API contract with React and Flutter integration guidance and disposable-MySQL lifecycle/migration tests.

### Changed

- Access tokens are bound to a device session; all protected requests check active account/session state, enabling immediate remote revocation on subsequent requests.
- Atomic refresh rotation preserves the device ID; refresh reuse and ordinary logout revoke the entire device family.
- Auth responses disable caching; browser write Origins must match configured frontend origins.
- Pre-upgrade access tokens require the normal refresh/retry flow once; existing refresh cookies are preserved by the migration.

### Migrations

- `20261009080000_qr_device_sessions`: additive device/challenge tables and data-preserving refresh-family backfill.

## 1.1.0 - 2026-10-05

### Added

- Task states `SKIPPED` and `MISSED`, with `closedAt` and `closeReason` task fields.
- `POST /tasks/:taskId/skip` (overdue recurring tasks; requires `reason`, 1–200 characters) and `POST /tasks/:taskId/miss` (any overdue task; requires `reason`, 1–200 characters). Both are versioned and idempotent, and they continue recurring series without duplicate occurrences.
- `status=skipped|missed` task list filters; `skippedCount` and `missedCount` on the dashboard summary.
- Release metadata: `GET /health` returns `version`, `commit`, and `builtAt`; every response carries `x-api-version`.

### Changed

- `openCount`, `overdueCount`, `pendingTodayCount`, `status=open`, and upcoming tasks include only `OPEN` tasks.
- `completionRate` and project progress exclude skipped tasks; missed tasks count as not completed.
- Skipped/missed tasks are terminal: reopen returns `409 TASK_NOT_REOPENABLE`; completion and subtask changes return `409 TASK_NOT_OPEN`.

### Migrations

- `20261005130000_task_skip_miss_states`
- `20261005133000_task_close_reason`

## 1.0.0 - 2026-09-30

- Initial production release: Google authentication with rotating refresh sessions, workspaces and preferences, hierarchical projects, tasks/subtasks with recurrence and optimistic concurrency, the dashboard aggregate, and proxy-aware rate limits.
