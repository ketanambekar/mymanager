# Habits API and Adam/Dartji Handoff

Backend **1.5.0**. Habits are read-only views of existing recurring task series: **Daily, Weekly, Monthly, Yearly, and every Custom interval/unit**. One-time tasks are excluded. No duplicate habit persistence or automatic completion/miss generation.

## Configuration and Auth

Paths are relative to `/api/v1`. Web uses `VITE_API_BASE_URL` (production `https://api.mymanger.in/api/v1`; local same-origin Vite proxy). Native uses `API_BASE_URL` via `--dart-define`.

All endpoints require a Bearer access token in Authorization. Existing session revocation and refresh handling remain in effect. Queries are workspace-scoped; other-user habits return 404. Responses use `Cache-Control: no-store`.

Success: `{ "success": true, "data": ... }`.
Errors: `{ "success": false, "error": { "code": "...", "message": "...", "requestId": "..." } }`.

- `400 VALIDATION_ERROR` includes validation details; unknown query fields are rejected.
- `401 AUTHENTICATION_REQUIRED` / `SESSION_EXPIRED`.
- `404 HABIT_NOT_FOUND` for missing, other-workspace, or representative one-time tasks.
- `404 PREFERENCES_NOT_FOUND` if the saved timezone record is missing.
- `500 INTERNAL_ERROR` for unexpected errors; inherited overall limits may return non-JSON 429.

## Identity and History Rules

- One habit per recurrence-series UUID. Never merge tasks by title.
- Representative task: highest occurrence number, then highest task ID, not latest due date. Its current title, project, and recurrence describe the habit.
- Legacy recurring tasks with no series UUID are standalone `task-<taskId>` habits.
- Every saved recurring occurrence counts by its actual due date, even if it has a different cadence from the representative task. Weekly/monthly/yearly/custom occurrences are no longer neutral `NOT_DAILY` entries.
- Reads never generate tasks or change their status. The existing recurrence catch-up can leave gaps.
- Missing days/periods are not automatic misses. Open overdue records remain overdue until explicitly completed/skipped/missed.
- Future saved occurrences remain accessible; history is not capped at today.
- This is current saved history, not an immutable audit. Due-date edits, recurrence edits, reopen, and deletion affect results.
- Existing recurrence edits are occurrence-only. Changing an occurrence to one-time detaches it from the series under the task contract; it is not a stop/delete-habit operation.

## Habit Shape

Returned in list items and `data.habit`:

```json
{
  "id": "edc33f26-33b4-4b4b-b3d0-89729fc4ab13",
  "title": "Weekly workout",
  "project": { "id": 12, "name": "Health", "color": "#1F6249" },
  "recurrence": { "frequency": "weekly", "interval": null, "unit": null },
  "periodUnit": "week",
  "latestOccurrence": {
    "taskId": 73, "dueDate": "2026-10-10", "status": "OPEN", "version": 1
  }
}
```

`recurrence.frequency`: `daily|weekly|monthly|yearly|custom`. Custom returns its actual interval (1-365) and unit (`day|week|month|year`). Non-custom interval/unit are null.

`periodUnit` is `day` for Daily, `week` for Weekly, `month` for Monthly, `year` for Yearly, or the Custom unit. A Custom every 3 weeks has `periodUnit: "week"` and recurrence interval 3: **unit buckets are presentation groups, not reconstructed three-week schedules**. Use the exact interval in labels.

`project` and `latestOccurrence.dueDate` may be null. Latest occurrence is not necessarily today's task or the latest saved date.

## `GET /habits`

Query: `limit` (1-100, default 50), optional opaque `cursor`, trimmed literal `search` (max 120), positive `projectId` (exact project, not descendants).

Returns 200:

```json
{
  "success": true,
  "data": {
    "asOfDate": "2026-10-09",
    "timezone": "Asia/Kolkata",
    "items": [],
    "nextCursor": null
  }
}
```

Items use the Habit Shape above. Sorted by habit ID, paginated over habits, not occurrences. Send `nextCursor` with unchanged filters until null; reset cursor when scope changes. SQL parameters treat search `%`/`_` literally. No total count is provided.

Responses are snapshot-consistent, but pagination across multiple requests is not a frozen snapshot. Deduplicate by ID and refetch after mutations.

## Recorded-History Navigation Metadata

Both calendar and history endpoints return:

```json
{
  "firstRecordedDate": "2024-02-29",
  "lastRecordedDate": "2099-12-20",
  "availableMonths": ["2024-02", "2026-06", "2026-08", "2099-12"],
  "undatedOccurrencesCount": 1
}
```

These cover **all saved dated series occurrences**, regardless of cadence, across all months. Undated occurrences are excluded. No dated history returns null date bounds and `availableMonths: []`.

Use these fields, not `latestOccurrence.dueDate`, as navigation bounds. Sorted months are unique, preserve future records, and allow navigation beyond gaps.

For initial selection, fetch the calendar without `month` to obtain the current month and metadata. If it has no records, choose the closest populated month by absolute calendar-month distance to `asOfDate.slice(0, 7)`; ties choose the earlier month. Fetch the chosen month explicitly (daily) or its year (period history). This is a **client selection rule**; backend omitted month/year still defaults to the saved-timezone current month/year.

Daily previous/next select adjacent `availableMonths`; non-daily year navigation uses sorted unique years derived from `availableMonths`. Disable beyond the first/last entry. Skip empty months/years without losing later populated history. If no dated history, show empty/undated history and disable navigation.

Hide outer dates outside `firstRecordedDate`/`lastRecordedDate` using weekday placeholders if necessary. Keep missing dates inside the bounds as `NOT_RECORDED`. Do not remove periods with saved occurrences or hide future records. Refetch metadata after edits/deletion.

## `GET /habits/:habitId/calendar?month=YYYY-MM`

Existing monthly grid remains available for **all** recurring cadences and detail views. Optional month: years 1900-2199 and months 01-12; defaults to saved-timezone current month.

Returns 200 with:

- `asOfDate`, `timezone`, `month`, `habit`.
- Recorded-history metadata above.
- Legacy `firstRecordedDueDate`: daily-only earliest saved date, retained for compatibility; **not navigation bounds**.
- `days`: one entry for every actual calendar day (28/29/30/31), ascending.
- Existing full-month `summary`: `daysInMonth`, `recordedDays`, `completedDays`, `skippedDays`, `missedDays`, `pendingDays`, `overdueDays`, `scheduledDays`, `notRecordedDays`, `notDailyDays`.

Example day:

```json
{
  "date": "2026-10-08",
  "state": "SKIPPED",
  "isToday": false,
  "occurrence": {
    "taskId": 64,
    "title": "Weekly workout",
    "status": "SKIPPED",
    "version": 2,
    "completedAt": null,
    "closedAt": "2026-10-09T06:00:00.000Z",
    "closeReason": "Rest week",
    "recurrence": { "frequency": "weekly", "interval": null, "unit": null }
  }
}
```

States: `COMPLETED`, `SKIPPED`, `MISSED`, `PENDING` (open due today), `OVERDUE` (open before today), `SCHEDULED` (open after today), `NOT_RECORDED` (no saved task). Missing dates have `occurrence: null`.

**1.5.0 intentional behavior change:** non-daily recurring records now use their real outcome states/counts, not `NOT_DAILY`. The legacy state/counter `NOT_DAILY`/`notDailyDays` is retained only for an anomalous one-time record still attached to a recurring series. Normal task edits detach one-time records.

Monthly count identities remain:

- `recordedDays + notRecordedDays === daysInMonth`.
- Completed + skipped + missed + pending + overdue + scheduled + legacy non-recurring days equals recordedDays.

Counts remain full-month even if the UI hides outside-history cells. For sparse/non-daily habits use **occurrence counts from `/history`**, not a daily completion percentage. An empty calendar date does not prove the habit was due.

## `GET /habits/:habitId/history?year=YYYY`

**New in 1.5.0.** Cadence-aware year history for weekly/monthly/yearly/custom views. Year is integer 1900-2199, defaults to saved-timezone current year. No pagination (at most one dated record per series/date, bounded to a calendar year).

Returns 200:

```json
{
  "success": true,
  "data": {
    "asOfDate": "2026-10-09",
    "timezone": "Asia/Kolkata",
    "year": 2026,
    "habit": {
      "id": "edc33f26-33b4-4b4b-b3d0-89729fc4ab13",
      "title": "Weekly workout",
      "project": null,
      "recurrence": { "frequency": "weekly", "interval": null, "unit": null },
      "periodUnit": "week",
      "latestOccurrence": { "taskId": 64, "dueDate": "2026-10-08", "status": "SKIPPED", "version": 2 }
    },
    "firstRecordedDate": "2026-10-08",
    "lastRecordedDate": "2026-10-08",
    "availableMonths": ["2026-10"],
    "undatedOccurrencesCount": 0,
    "periodUnit": "week",
    "summary": {
      "recordedOccurrences": 1,
      "completedOccurrences": 0,
      "skippedOccurrences": 1,
      "missedOccurrences": 0,
      "pendingOccurrences": 0,
      "overdueOccurrences": 0,
      "scheduledOccurrences": 0,
      "nonRecurringOccurrences": 0
    },
    "periods": [
      {
        "startDate": "2026-10-05",
        "endDate": "2026-10-11",
        "summary": {
          "recordedOccurrences": 1,
          "completedOccurrences": 0,
          "skippedOccurrences": 1,
          "missedOccurrences": 0,
          "pendingOccurrences": 0,
          "overdueOccurrences": 0,
          "scheduledOccurrences": 0,
          "nonRecurringOccurrences": 0
        },
        "occurrences": [
          {
            "date": "2026-10-08",
            "state": "SKIPPED",
            "isToday": false,
            "occurrence": {
              "taskId": 64, "title": "Weekly workout", "status": "SKIPPED", "version": 2,
              "completedAt": null, "closedAt": "2026-10-09T06:00:00.000Z",
              "closeReason": "Rest week",
              "recurrence": { "frequency": "weekly", "interval": null, "unit": null }
            }
          }
        ]
      }
    ]
  }
}
```

Period bounds are inclusive dates; order is ascending. Weekly buckets run **Monday-Sunday** and can cross a year boundary. Only occurrences whose due date belongs to the requested year are returned, so boundary weeks are partial snapshots: do not sum them across years as complete-week scores.

Monthly buckets are calendar months; yearly bucket is Jan 1-Dec 31; day buckets are individual recorded dates. Period grouping uses the representative habit's unit; each occurrence includes its historical recurrence, so cadence changes remain visible.

Only populated buckets are returned. Empty year: `periods: []`, all summary counts zero, navigation metadata still covers all years. **No expected schedule is synthesized**, no zero-filled missed periods, no one-status-per-week assumption. Multiple outcomes in one period remain individual entries and counts.

Summary is for saved occurrences in the requested year; period summary is for that period's returned occurrences. All outcome counters sum to `recordedOccurrences`. A year may contain several monthly occurrences or a custom interval may span years; the exact due dates/interval are authoritative.

## Existing Task Actions

Use [Tasks API](tasks.md), not new habit mutations. Fetch full task/subtask details by selected occurrence's `taskId`. Complete/reopen/skip/miss use latest task version. Completion rejects future dates and incomplete subtasks. Skip/Miss are overdue-only with required reasons; skipped/missed records cannot reopen.

Refresh habit list/history/calendar after mutations or conflict. Never mutate a whole bucket or use representative task ID to modify another selected occurrence. No action for empty dates.

## Frontend Integration for Adam

- Feature `client/src/features/habits/`: repository owns list/calendar/new `history` HTTP calls; `use_habit_controller.js` owns selected habit/month/year, loading/errors, and stale-response protection; view/widgets render cadence-specific history.
- Remove Daily-only assumptions. List all returned habits and show recurrence badges: Daily, Weekly, Monthly, Yearly, or “Every N days/weeks/months/years”.
- Use `habit.periodUnit` to select presentation:
  - `day`: monthly calendar (custom day interval: emphasize saved due dates, neutral gaps).
  - `week`: yearly week-row/card timeline from `/history?year=`, Monday-Sunday labels, each saved outcome/date and period counts.
  - `month`: yearly month-card list from history, showing populated months and their occurrences.
  - `year`: year summary/card with saved occurrences; year navigation derived from recorded months.
- For Custom keep interval in the header; buckets are unit-based, not N-unit reconstructed schedules. Do not count all days of a week or all months in a year as required work.
- On initial selection use the nearest-populated-month rule above; for period views request its year. History year/month jumps use recorded metadata, not representative due dates or today caps.
- Details show due date, historical recurrence, outcome, timestamps, reason. One bucket can have multiple outcomes; use counts/chips rather than a fabricated single completed/skipped period state.
- Label non-daily totals **Completed occurrences / Skipped occurrences / Missed occurrences**, not “days”.
- Preserve daily inner `NOT_RECORDED` gaps. For sparse period timelines display a gap/separator if useful; don't synthesize missed weeks/months.
- States: list/calendar/history loading and errors, empty list, undated-only/no dated history, empty requested year, deleted selection, pagination failure, auth failure, mutation conflict. No demo fallback.
- Reuse existing themes and accessibility; tablet/phone reflow list/history without removing states. Use server `asOfDate`, date strings without timezone shifting, localize only timestamp instants.
- Verify all five cadences and custom intervals >1, mixed-cadence history, several outcomes per week/month, Dec/Jan partial weeks, future scheduled records, gaps and nearest-month/year navigation, undated history, exact counters, task changes, and other-account 404.

## Flutter Integration for Dartji

Bind the same contract in `mobile/lib/features/habits/` repositories/models/GetX controller/widgets using shared Dio and `API_BASE_URL`. Model recurrence, periodUnit, nullable metadata, period arrays, counters, and each historical occurrence. Follow Adam's cadence-specific views, initial selection, boundary-week warning, empty/gap handling, and exact interval labels.

Native auth is unchanged: verify Google token audience matches `GOOGLE_CLIENT_ID` for initial login, and Dio HttpOnly-cookie refresh/rotation, logout, secure OS-backed cookie persistence, and revoked-session failure before shipping. Access tokens remain in memory; native CORS does not define native cookie behavior. See [auth](auth.md) and [QR/device native handoff](qr_sessions.md#flutter-integration-for-dartji).

Verify native phone/tablet layout, background/resume refresh, all cadences/custom intervals, UTC date-only handling, empty history, and remote logout. No native-specific auth implementation is supplied here.

## Verification / Rollout

Build `npm --prefix server run build`; unit regressions `npm --prefix server test`; disposable local MySQL `npm --prefix server run test:habits:integration`. Integration refuses non-local hosts and needs create/drop permission.

1.5.0 requires **no new migration** beyond the existing 1.3.0 lookup index. Deploy the backend before integrating new fields/endpoints. The earlier recorded-history metadata work is included in this release.
