# Habits API and Page Handoff

Backend **1.3.0**. A read-only view of existing daily task recurrence series, not a second habit database. Task CRUD/completion/Skip/Miss and recurrence behavior remain unchanged.

## Product and Data Rules

- One habit per `recurrenceSeriesId`, not one habit per occurrence or per title. Two independently created tasks with the same title are separate habits.
- Daily means `DAILY` or `CUSTOM` with interval **1**, unit **DAY**. Every two days, weekly, monthly, yearly, and one-time tasks are excluded.
- The highest `occurrenceNumber`, then highest task ID, is the representative occurrence for each series. Its recurrence must be daily for the series to appear. Its current title and project supply list metadata; due-date order is not used because task dates can be edited.
- IDs are stable recurrence-series UUIDs. A legacy daily task with no series ID is a standalone habit with ID `task-<taskId>`; do not try to merge legacy tasks by matching titles.
- These endpoints **do not materialize or mutate tasks**. Loading the Habits page cannot create overdue copies, complete tasks, or close days.
- The existing recurrence catch-up creates only the latest due occurrence, and task completion can jump to the next future occurrence. Therefore there can be unrecorded days between saved occurrences.
- A missing date is **NOT_RECORDED**, never an assumed Skip or Miss. This includes dates before the first saved occurrence and future dates without a saved task. The API does not invent future scheduled days either.
- A stored `OPEN` occurrence in the past is **OVERDUE**, not automatically missed. Only explicit Skip/Miss commands count as skipped/missed.
- A calendar entry belongs to its **due date**, not the day its completion/closure was submitted. A task due Oct 1 completed Oct 5 marks Oct 1 completed; its `completedAt` remains available as detail.
- This is a view of current stored task history, **not an immutable audit log**. Reopening, editing due dates/recurrence, deleting occurrences, and project changes affect the view. Deleted history cannot be recovered through this API.
- Existing task edits are occurrence-only, not series-wide edits. If a latest occurrence remains in the series but changes to a non-daily cadence, the habit disappears until the latest occurrence is daily again. Changing to one-time detaches that occurrence under the existing task contract; it does not stop or delete other members of the old series. No new stop/archive/delete-habit command is provided.

## Configuration, Authentication, and Envelopes

- Web uses existing `VITE_API_BASE_URL`; production `https://api.mymanger.in/api/v1`. Local web development uses the existing same-origin Vite proxy.
- Flutter uses `API_BASE_URL` via `--dart-define`, with the API root ending `/api/v1`.
- All paths below are relative to that root and require an access token in the Authorization header using the **Bearer** scheme. Device/session revocation checks are unchanged.
- Every lookup/query is scoped to the authenticated workspace. Another workspace's habit returns 404, never its metadata/history.
- Responses have `Cache-Control: no-store`. Success is `{ "success": true, "data": ... }`.
- Validation: `400 VALIDATION_ERROR` with `error.details`. Authentication: `401 AUTHENTICATION_REQUIRED` / `SESSION_EXPIRED`. Missing, non-daily, deleted, or other-tenant selection: `404 HABIT_NOT_FOUND`.
- A missing preference record returns `404 PREFERENCES_NOT_FOUND`; no silent browser-timezone fallback.
- Errors use the standard `{ "success": false, "error": { "code": "...", "message": "...", "requestId": "..." } }` envelope. Unexpected failures use `500 INTERNAL_ERROR`. The inherited overall IP rate limit can return a non-JSON 429; use the existing transport error handling.

## `GET /habits`

Query parameters:

| Name | Meaning |
| --- | --- |
| `limit` | Integer 1-100; default 50 |
| `cursor` | Opaque habit ID returned as `nextCursor`; omit on the first page |
| `search` | Optional trimmed text, max 120 characters; literal title substring on the representative occurrence |
| `projectId` | Optional positive project ID; exact project only, not descendants |

Unknown query fields are rejected. No request body. Returns **200**:

```json
{
  "success": true,
  "data": {
    "asOfDate": "2026-10-09",
    "timezone": "Asia/Kolkata",
    "items": [
      {
        "id": "edc33f26-33b4-4b4b-b3d0-89729fc4ab13",
        "title": "Walk daily",
        "project": { "id": 12, "name": "Health", "color": "#1F6249" },
        "latestOccurrence": {
          "taskId": 73,
          "dueDate": "2026-10-10",
          "status": "OPEN",
          "version": 1
        }
      }
    ],
    "nextCursor": null
  }
}
```

`project` and `latestOccurrence.dueDate` can be null. `latestOccurrence.status` is the original task enum, not a calendar display state. The latest occurrence might be tomorrow's already-created task; it is **not necessarily today's task**.

Pagination is over habit IDs sorted ascending, not task rows or titles. Pass `nextCursor` with the same search/project scope until null; reset pagination when filters change. SQL search is parameterized and treats `%`/`_` literally rather than as wildcards. Comparison/case handling follows the database collation.

Each response has a repeatable-read snapshot. There is no cross-request pagination snapshot: concurrent changes may add/remove habits between pages. Deduplicate by habit ID and refresh the list after task mutations. No total-count field is supplied; do not claim the first page is the full habit list.

## `GET /habits/:habitId/calendar`

Path `habitId`: exact ID from the list (UUID or `task-<positiveTaskId>`), **not** `latestOccurrence.taskId`.

Query `month`: optional `YYYY-MM`, supported years **1900-2199**, valid months 01-12. Omit to use the current month in the saved user timezone. Unknown query fields are rejected. No body. Returns **200**:

```json
{
  "success": true,
  "data": {
    "asOfDate": "2026-10-09",
    "timezone": "Asia/Kolkata",
    "month": "2026-10",
    "habit": {
      "id": "edc33f26-33b4-4b4b-b3d0-89729fc4ab13",
      "title": "Walk daily",
      "project": { "id": 12, "name": "Health", "color": "#1F6249" },
      "latestOccurrence": { "taskId": 73, "dueDate": "2026-10-10", "status": "OPEN", "version": 1 }
    },
    "firstRecordedDueDate": "2026-10-01",
    "undatedOccurrencesCount": 0,
    "summary": {
      "daysInMonth": 31,
      "recordedDays": 7,
      "completedDays": 3,
      "skippedDays": 1,
      "missedDays": 1,
      "pendingDays": 1,
      "overdueDays": 0,
      "scheduledDays": 1,
      "notRecordedDays": 24,
      "notDailyDays": 0
    },
    "days": [
      {
        "date": "2026-10-01",
        "state": "COMPLETED",
        "isToday": false,
        "occurrence": {
          "taskId": 64,
          "title": "Walk daily",
          "status": "COMPLETED",
          "version": 2,
          "completedAt": "2026-10-01T14:20:00.000Z",
          "closedAt": null,
          "closeReason": null
        }
      },
      {
        "date": "2026-10-02",
        "state": "SKIPPED",
        "isToday": false,
        "occurrence": {
          "taskId": 65,
          "title": "Walk daily",
          "status": "SKIPPED",
          "version": 2,
          "completedAt": null,
          "closedAt": "2026-10-03T06:00:00.000Z",
          "closeReason": "Rest day"
        }
      },
      {
        "date": "2026-10-03",
        "state": "NOT_RECORDED",
        "isToday": false,
        "occurrence": null
      }
    ]
  }
}
```

The example abbreviates `days`; the real response **always contains exactly one entry per day in the requested month**, ascending, including all missing/future dates and leap days. There is no calendar pagination.

### Calendar states

| `state` | Meaning / suggested label |
| --- | --- |
| `COMPLETED` | Stored daily occurrence completed / Done |
| `SKIPPED` | Explicit stored Skip / Skipped |
| `MISSED` | Explicit stored Miss / Missed |
| `PENDING` | Open occurrence due on `asOfDate` / Pending today |
| `OVERDUE` | Open occurrence before `asOfDate` / Overdue |
| `SCHEDULED` | Open occurrence after `asOfDate` / Scheduled |
| `NOT_RECORDED` | No saved occurrence for the date / Not recorded |
| `NOT_DAILY` | Saved occurrence in this series was a different cadence / Not a daily occurrence |

`NOT_DAILY` may occur when recurrence was edited within a still-current daily series. Its task details are returned, but it does not count as a completed/skipped/missed **habit day**. Do not render it as a normal missed day.

All summary counts apply to **the selected month only**. `recordedDays` includes all days with an occurrence, including `NOT_DAILY`.

Exact identities:

- `recordedDays + notRecordedDays === daysInMonth`
- `completedDays + skippedDays + missedDays + pendingDays + overdueDays + scheduledDays + notDailyDays === recordedDays`

No lifetime totals, completion rate, inferred missed count, or streak are supplied. Do not calculate a completion percentage using unrecorded days as failures.

`firstRecordedDueDate` is the earliest remaining daily occurrence due date across the series (null if all are undated), **not a proven habit creation/start date**. `undatedOccurrencesCount` is the number of stored undated occurrences across that habit's series, not a monthly count; those cannot be placed on the calendar.

Date-only values (`date`, `month`, due dates, `asOfDate`) are calendar strings, not UTC instants. Do not run them through timezone conversion that shifts the calendar day. `completedAt`/`closedAt` are ISO timestamps that may be localized for details.

The month selection, representative task, historical records, and summary use one database snapshot. No mutation version is required for these reads. Refetch after changes; do not assume an old response is an immutable audit.

## Existing Task Actions

This page can initially be purely informational. If Adam adds actions, use the existing [Tasks API](tasks.md); do not invent habit-specific mutation endpoints:

- Fetch `GET /tasks/:taskId` for complete task/subtask details using the selected day's `occurrence.taskId`.
- Send latest task `version` to complete/reopen/skip/miss commands.
- Completion still requires all subtasks complete and rejects future-dated tasks.
- Skip/Miss remain **overdue-only**; Skip requires recurrence, and both require a 1-200 character reason. Calendar today cannot be skipped under the current task contract.
- Skipped/missed tasks cannot be reopened. A `NOT_RECORDED` day has no task ID and no task action.
- Refetch calendar and list after a successful command or version conflict. The latest task ID from the habit list must not be used to mutate a different selected calendar day.

## Frontend Integration for Adam

1. Add a separate authenticated **Habits** route/page, suggested `/habits`, and a navigation entry beside the workspace/task view. Do not replace the dashboard or its existing mobile Tasks/Projects navigation.
2. Suggested feature: `client/src/features/habits/`:
   - `habit_repository.js`: list and selected-month calendar endpoints, using the shared `api_client.js` and normal 401 refresh/retry.
   - `use_habit_controller.js`: habit pagination/search/project filter, selected habit ID, selected month, loading/errors, and request cancellation/stale-response guards.
   - `habit_view.jsx`: desktop list on the left, selected calendar on the right; stack/select panels appropriately on mobile.
   - Focused `widgets/habit_list/`, `widgets/habit_calendar/`, and day-details components as needed.
3. List rows use `items[].id` as their keys and selection; show title/project. Add load-more when `nextCursor` exists or explicitly fetch all pages before calling it a full list.
4. On first load select the first returned habit, then request its calendar without `month` to get the server's current month. Store `data.month` and use `asOfDate` for the today indicator and task guards; never invent today from the browser clock.
5. Calendar header has month navigation and “This month”. Use the returned dates to arrange the grid; add blank leading/trailing cells locally without counting them as returned habit days. Preserve 28/29/30/31-day month lengths.
6. Render the seven substantive states plus neutral `NOT_DAILY`, with an accessible legend and labels/icons as well as color. Reuse the existing theme tokens/project colors. Never rely on color alone.
7. Above/below the grid show **Done**, **Skipped**, and **Missed** using `summary.completedDays`, `skippedDays`, `missedDays`. Optionally show Pending/Overdue and an honest recorded-days coverage label.
8. Clicking a day opens details with due date, recorded title/status, localized completion/closure timestamp, and the saved skip/miss reason. Missing dates show “No saved occurrence for this day”, not zero-work or automatic Miss.
9. Explain incomplete history: “Only saved task occurrences are shown. Gaps do not mean the habit was missed.” Show an undated-history notice when `undatedOccurrencesCount > 0`.
10. If task actions are offered, use selected-day IDs/versions and existing task dialogs/rules. Prefer read-only calendar for the first UI release; no new create-habit form is required because creating a daily task already creates a habit.
11. On habit/month/filter changes cancel old requests or ignore stale replies. Keep results bound to their habit/month; never show habit A's delayed response under habit B. Reset pagination after scope changes.
12. Handle `404 HABIT_NOT_FOUND` after a recurrence edit/deletion by refreshing the list and asking the user to select another habit. Do not silently reuse the previous habit's calendar.

Required states: initial list loading, empty/no daily tasks, search with no matches, pagination pending/failure, selected calendar loading, month with no records, undated history, unknown selection, transport/auth/rate-limit error with retry, and mutation conflict when actions are offered. Preserve explicit error messaging; no demo/seed history fallback.

### Adam verification flow

- Create a Daily task; confirm one list entry across multiple generated occurrences. Create Custom every 1 day and every 2 days; include only the first.
- Complete, reopen, skip, and miss stored occurrences through the dashboard; refetch Habits and verify the due-day state/count and saved reason.
- Complete an old task today: the old due-date cell must change, not the current day.
- Test catch-up gaps, future dates, undated legacy tasks, empty months, leap February, monthly navigation, search, and pagination.
- Test two independent habits with the same title, occurrence-only rename/date edits, and deletion: no title-based merging or frozen/deleted history.
- Change latest cadence to weekly and refresh: that series is no longer listed. Understand existing one-time detachment behavior before offering any “stop habit” UI.
- Verify mobile layout, keyboard/day-detail accessibility, light/dark themes, stale request switching, error retry, and other-account isolation.

## Flutter Integration for Dartji

- Suggested future feature `mobile/lib/features/habits/`: `habit_repository.dart`, typed models for list/calendar/day states, `HabitController` with GetX bindings, `habit_screen.dart`, list/calendar/details widgets. The current native app is a starter; no complete auth integration is assumed.
- Use shared Dio with `API_BASE_URL` from `--dart-define`. These are bearer-authenticated read endpoints; map all enum states, nullable occurrence/project fields, pagination and errors exactly.
- Use strings/date-only calendar models for `YYYY-MM-DD`, not local conversion of UTC instants. Compare against server `asOfDate`; localize only timestamp details. Month navigation and null/default month match the web.
- GetX controller owns selected habit/month, pagination, loading/error states, and cancellation/stale-reply guards. Reflow list/calendar for phone/tablet without omitting unrecorded/missed/skipped distinctions.
- Camera/QR login is unrelated to this feature. Initial native Google authentication still requires ID-token audience matching server `GOOGLE_CLIENT_ID`; browser GIS is not native sign-in.
- Native refresh remains HttpOnly-cookie based: verify Dio cookie rotation, path scoping, logout/remote-revocation behavior, and secure OS-backed persistence before shipping authenticated screens. Keep access tokens in memory; native CORS is not a substitute for native cookie/session handling. See [Authentication](auth.md) and [QR/device native handoff](qr_sessions.md#flutter-integration-for-dartji).
- Verify two separate native/browser account contexts, month boundaries in differing timezones, background/resume refetch, task-mutation parity, pagination, leap months, neutral gaps, and refresh failure returning to login. If secure native auth/cookie behavior cannot be confirmed, that prerequisite remains blocked; do not weaken backend authorization.

## Backend Verification and Rollout

- `npm --prefix server run build`: generate Prisma Client and strict TypeScript compile.
- `npm --prefix server test`: includes calendar state/count, leap/empty month, eligibility/identity, and query-boundary tests.
- `npm --prefix server run test:habits:integration`: disposable local MySQL, migration chain, real HTTP validation/auth, grouping/pagination/filtering, history totals/gaps, task command parity, date/recurrence edits/deletion, and tenant isolation. Requires local create/drop database privileges and refuses non-local hosts.
- Migration `20261009093000_habit_series_lookup` adds a lookup index only; no table/data backfill or inferred historical entries.
- Back up before applying migrations to populated databases. Frontend can ship only after backend 1.3.0 and the migration are deployed. This implementation does not deploy or commit automatically.
