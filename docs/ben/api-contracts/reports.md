# Reports API and Profile-Route Handoff

Backend **1.6.0**. Read-only analytics from existing saved tasks, recurrence occurrences, projects, completion/closure timestamps, and reasons. No new tables, generated task history, demo chart values, or external analytics services.

## Endpoint

**`GET /reports?year=2026`**, relative to the configured API root.

- Web `VITE_API_BASE_URL`, production `https://api.mymanger.in/api/v1`; local same-origin Vite proxy.
- Flutter `API_BASE_URL` via `--dart-define`.
- Requires Bearer access token in Authorization and an active device session. Workspace scope comes only from that token; no user/workspace query parameters.
- Optional `year`: integer 1900-2199; default current year in saved user timezone.
- Unknown query parameters rejected. No body, mutation version, or pagination.
- `Cache-Control: no-store`; one repeatable-read database snapshot including preference/timezone.
- `200 { "success": true, "data": ... }`.
- `400 VALIDATION_ERROR` (with details), `401 AUTHENTICATION_REQUIRED` / `SESSION_EXPIRED`, `404 PREFERENCES_NOT_FOUND`, `500 INTERNAL_ERROR`. Errors use `{ success: false, error: { code, message, requestId } }`; inherited overall IP limiter can return a non-JSON 429.

## Response Structure

All outcome objects have:

```json
{
  "total": 10,
  "completed": 5,
  "skipped": 2,
  "missed": 1,
  "open": 2,
  "rated": 8,
  "completionRate": 63
}
```

`total = completed + skipped + missed + open`. `rated = total - skipped`; misses and open tasks remain in the denominator. Percentage is integer-rounded; **null** if the denominator is zero (including all-skipped populations). Render null as "No rated data", not 0%.

Top-level fields:

| Field | Scope / content |
| --- | --- |
| `generatedAt` | ISO response snapshot time |
| `asOfDate`, `timezone`, `year` | Saved-timezone today and selected year |
| `scope` | `{ dueFrom: "2026-01-01", dueTo: "2026-12-31", basis: "saved_occurrences" }` |
| `dueSummary` | Selected-year **due-date** cohort outcome object plus `overdue`, `onTimeCompleted`, `lateCompleted`, `completionTimingUnknown`, `onTimeRate` |
| `activitySummary` | `{ completed, skipped, missed }` actions with recorded timestamps inside the selected local year |
| `monthly` | Exactly 12 ascending `{ month: "YYYY-MM", due: <outcomes>, activity: { completed, skipped, missed } }` entries |
| `activityDays` | Sorted populated local dates `{ date, completed, skipped, missed }`; empty days omitted |
| `recurringSummary` | Outcome object for recurring selected-year due occurrences, plus `seriesCount` |
| `habits` | `{ items: [...], totalSeries, limit: 10 }` recurring series ranked by completed count descending, ID tie-break |
| `reasons` | `{ items: [{ status: "SKIPPED", reason: "Rest day", count: 3 }], totalReasons, limit: 10 }` selected-year due cohort, ranked count descending |
| `currentInventory` | **All-time current saved tasks**, outcome object plus `overdue`, `undated` |
| `projects` | **Current all-time direct top-level task outcomes**, `{ items: [...], totalProjects, limit: 20, unassigned: <outcomes> }` |

Example trend entry:

```json
{
  "month": "2026-10",
  "due": {
    "total": 10, "completed": 5, "skipped": 2, "missed": 1,
    "open": 2, "rated": 8, "completionRate": 63
  },
  "activity": { "completed": 7, "skipped": 1, "missed": 2 }
}
```

Activity can differ from due counts: tasks due September can be completed in October. Those counts must not be drawn as if they shared the same cohort.

Habit result:

```json
{
  "id": "<series-uuid-or-task-id>",
  "title": "Weekly workout",
  "recurrence": { "frequency": "weekly", "interval": null, "unit": null },
  "total": 4, "completed": 2, "skipped": 1, "missed": 1,
  "open": 0, "rated": 3, "completionRate": 67
}
```

Habit title/cadence here come from the highest occurrence number/ID **within the selected due-year recurring cohort**, not necessarily current series metadata. All recurring cadences/custom intervals count; one-time tasks don't. For current habit details use [Habits API](habits.md). Ranked subsets explicitly report totals/limits; do not claim the top ten are the complete habit list.

Project row: `{ id, name, color, parentProjectId, ...<outcomes> }`. Ranked by direct task total descending, ID tie-break; first 20 returned. This intentionally measures **direct parent-task outcomes only**: no subtasks, no descendant rollups. It is not the dashboard's branch/subtask progress metric. Label it accordingly, and show unassigned separately. Empty projects remain zero-count rows, null percentage.

## Metric Semantics and Honest Limits

- Due dates are date-only strings. Completed/closed instants are localized to saved timezone for activity/on-time comparisons. Never shift due dates through browser timezone conversion.
- On-time completion: known completion local date <= due date. Late: local completion date > due date. `onTimeRate` denominator is completed due-year tasks with a known completion timestamp; missing timestamps are counted separately and not invented.
- Overdue means OPEN with saved due date before `asOfDate`. Future occurrences remain in due totals; this rate is a current cohort snapshot, **not a success probability or historical final rate**.
- Undated tasks do not enter due-year charts, but may contribute to timestamp activity and always enter current inventory.
- Zero monthly outcome counts mean no saved due occurrences in that month; they are not proof of zero work or missed requirements. Activity days omitted from the array likewise do not prove inactivity.
- Recurrence catch-up skips materialization gaps. No inferred misses, streaks, expected-period totals, time tracking, productivity scores, XP, financial/health claims, or behavioral predictions.
- Records reflect **current saved state**, not an immutable event log. Reopen clears completion timestamps; edited/deleted history changes reports. Activity counts are current terminal outcomes with saved timestamps, not every past click/action.
- Reasons are verbatim user text grouped by exact status/reason; empty legacy reasons aren't fabricated. Render plain text, never HTML; no sentiment analysis or external transmission.
- Year report and current workload/project sections deliberately have different scopes. Display explicit scope labels; don't relabel current inventory/projects as selected-year numbers.
- Requests never materialize overdue occurrences, mutate tasks, or add timestamps. Refresh after mutations.

## Frontend Integration for Adam

**Entry point only in Profile/account menu.** Add "Reports" there, linking to a separate authenticated **`/profile/reports`** route. Do not insert Reports into the main Tasks/Projects/Habits navigation or load analytics on every dashboard request.

Suggested `client/src/features/reports/`:

- `report_repository.js`: `getReport(year)` using shared API client and normal session refresh/retry.
- `use_report_controller.js`: year selection, initial current-year request without `year`, loading/error/retry, AbortController or stale-response guard, explicit refresh.
- `report_view.jsx` and focused widgets: KPI strip, outcome distribution, monthly trend, activity calendar, project outcomes, recurring-series results, reasons, data-quality notice.

Design/binding guidance:

1. Header: Reports, selected year, timezone, snapshot "Updated at", back to profile/workspace. Use API returned year and `asOfDate`, not browser today.
2. KPI strip: completed/skipped/missed/open, completion rate, on-time rate; null-rate state and timing-unknown count visible.
3. Outcome distribution: accessible stacked bars/donut only from actual values. Distinct icons/text for skipped/missed; no sample data or decorative chart values.
4. Monthly due outcomes chart uses `monthly[].due`. A separate activity trend uses `monthly[].activity`, clearly titled **Actions recorded by month**. Don't combine these into a single misleading stacked total.
5. Activity heatmap uses `activityDays`. Build visual blank calendar cells locally but label them "No recorded actions", not "Missed". Explain current saved-state limits.
6. Recurring habit results: recurrence badge and recorded occurrence counts, with "Top 10 by completions" and `totalSeries`. Link to existing habit detail only using ID. No streak/expected-success invention.
7. Project section: "Current direct task outcomes" with hierarchy label and top-20 indicator. Do not compare its percentage directly to dashboard branch/subtask progress.
8. Reasons: count badges and plain text, distinct Skip vs Miss. Useful observations may quote actual counts, never infer causes from text.
9. Separate **Current workload** panel labels inventory as all-time current data; undated and overdue counts visible.
10. Support narrow/mobile layout, both themes, keyboard access, visible legends, reduced motion, and chart text/table alternatives. Reuse design tokens; no new chart dependency is required by backend.

Required states: initial loading, year change pending, data present, no saved due history, no timestamp activity, null rates, truncated ranked sections, error/retry, expired auth. Old responses must not appear under a newly selected year. No seed fallback; keep loading honest.

Optional print/save-as-PDF can use browser print after a successful report load. Backend doesn't provide PDF/CSV/download routes; don't invent them or put report secrets into URLs. If exports are requested later, agree on a contract first.

Verification: profile-only link and separate route; all four outcomes, skipped denominator, misses, empty/all-skipped year, late completion vs due-date attribution, timezone/year-boundary actions, unknown timestamps, undated tasks, all recurring cadences, non-doubled project totals, ranking limits, mutation refetch, request races, mobile/accessibility, and other-account isolation.

## Flutter Integration for Dartji

Suggested `mobile/lib/features/reports/`: Dio repository, typed models, ReportsController/GetX binding, report screen and focused KPI/trend/period widgets. Add route `/profile/reports` from the profile screen only; preserve dashboard navigation.

Configure shared Dio `API_BASE_URL` via `--dart-define`; Bearer access token stays in memory. Null ratios, year scope, sorted month/day strings, current-vs-selected scopes, ranking truncation and history caveats match Adam's binding exactly. Do not treat date-only due strings as instants.

Native auth prerequisites remain: Google ID-token audience must match server `GOOGLE_CLIENT_ID`, and Dio HttpOnly-cookie refresh rotation/path handling, secure OS-backed persistence, logout/revocation failure must be verified. Browser CORS/SameSite behavior does not define native cookies. See [auth](auth.md) and [device contract](qr_sessions.md#flutter-integration-for-dartji).

GetX controller owns lifecycle, year/loading/errors, stale-response rejection and resume refetch. No network calls in widget build. Native export/print is not covered; don't assume browser print is portable.

Verify phone/tablet, light/dark themes, text scaling, period counts, null/empty state, background/resume, timezone boundaries and auth failures. If secure native auth isn't confirmed, that prerequisite remains blocked.

## Backend Verification / Deployment

No new migration. Standard build and unit suite; report HTTP/database scenarios run inside `npm --prefix server run test:habits:integration` alongside the tightly coupled recurrence data tests.

Deployment uses a committed, tagged 1.6.0 bundle after a verified backup. Production verification must check release health, authentication boundary and read-only report identities; do not log user report contents or tokens.
