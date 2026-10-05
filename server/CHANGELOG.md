# MyManger API Changelog

All notable backend changes are recorded here. The version in `package.json` is the single source of truth and follows [Semantic Versioning](https://semver.org/):

- **Major**: breaking change for existing clients (removed/renamed endpoint or field, changed meaning that breaks a released client).
- **Minor**: new endpoint, field, state, or migration that existing clients can tolerate.
- **Patch**: bug fix, security fix, or internal change with no contract change.

Each deployed release is tagged `server-v<version>`. Check the running version with `GET /health` or the `x-api-version` response header.

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
