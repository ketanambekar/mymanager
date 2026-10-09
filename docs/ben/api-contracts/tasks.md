# Tasks and Subtasks API Contract

Base URL: `VITE_API_BASE_URL`. All requests require a bearer access token.

All recurring task series also appear in the read-only [Habits calendar and period-history API](habits.md). Its entries use saved occurrence due dates; gaps are not inferred misses. Existing task edits/deletion and commands remain authoritative for habit history.

## Task Endpoints

- `GET /tasks?status=all|open|completed|skipped|missed&projectId=&search=&dateScope=recent|upcoming|all&cursor=&limit=50`
- `GET /tasks/:taskId`
- `POST /tasks`
- `PATCH /tasks/:taskId`
- `DELETE /tasks/:taskId`
- `POST /tasks/:taskId/complete`
- `POST /tasks/:taskId/reopen`
- `POST /tasks/:taskId/skip`
- `POST /tasks/:taskId/miss`

Create body:

```json
{
  "title": "Ship release notes",
  "projectId": 12,
  "dueDate": "2026-10-01",
  "recurrence": { "frequency": "custom", "interval": 2, "unit": "week" }
}
```

`projectId` and `dueDate` may be null. A missing create date defaults to today in the saved user timezone. Frequencies: `one_time`, `daily`, `weekly`, `monthly`, `yearly`, `custom`. Custom interval is 1–365 and requires `day`, `week`, `month`, or `year`.

Patch accepts the same fields plus required `version`. Complete/reopen bodies are `{ "version": 3 }`. Completion returns the updated occurrence; recurring completion creates one future occurrence with fresh open subtasks.

List returns `{ items, nextCursor }`. Continue with `cursor=<nextCursor>` until null.

## Task States

Each task returns `status`: `OPEN`, `COMPLETED`, `SKIPPED`, or `MISSED`. `completed` is a convenience boolean that is true only for `COMPLETED`, so `completed: false` does **not** mean open. Use `status` to decide between open and closed. `completedAt` is set only for `COMPLETED`; `closedAt` is set only for `SKIPPED`/`MISSED`. `closeReason` holds the user's skip or miss reason; it is null for `OPEN` and `COMPLETED`.

| From | Command | To |
| --- | --- | --- |
| `OPEN` | `complete` | `COMPLETED` |
| `OPEN` (overdue, recurring) | `skip` | `SKIPPED` |
| `OPEN` (overdue) | `miss` | `MISSED` |
| `COMPLETED` | `reopen` | `OPEN` |

`SKIPPED` and `MISSED` tasks cannot be reopened (`409 TASK_NOT_REOPENABLE`), completed, gain subtasks, or have subtasks completed/reopened (`409 TASK_NOT_OPEN`). Title, project, date, and recurrence edits are still allowed.

## Skip and Miss

`POST /tasks/:taskId/skip` with body `{ "version": 3, "reason": "Rest day" }`, and `POST /tasks/:taskId/miss` with body `{ "version": 3, "reason": "Forgot about it" }`. Both require `reason`: it's trimmed and must be 1–200 characters. A missing, blank, or too-long reason, or any extra field, returns `400 VALIDATION_ERROR`. Both return `200` with the updated occurrence:

```json
{
  "success": true,
  "data": { "id": 41, "status": "SKIPPED", "completed": false, "completedAt": null, "closedAt": "2026-10-05T12:40:11.204Z", "closeReason": "Rest day", "dueDate": "2026-10-03", "version": 4, "recurrence": { "frequency": "daily", "interval": null, "unit": null }, "subtasks": [] }
}
```

Skip means "I chose not to do this occurrence"; Miss means "I meant to, but it didn't happen". The server accepts any free text. Suggested client-side presets:

| Skip | Miss |
| --- | --- |
| Rest day | Forgot about it |
| Not feeling well | Ran out of time |
| Travelling or away | Something urgent came up |
| Busy with higher-priority work | Low energy or motivation |
| Not needed this time | Blocked or waiting on someone |

Example: a daily task due Oct 4 is still open on Oct 5. The dashboard already shows both the overdue Oct 4 task and an open Oct 5 task. Skipping or missing Oct 4 only closes Oct 4. Oct 5 stays open, and no duplicate is created.

- **Overdue** means `dueDate` is before today in the user's saved timezone. Undated, due-today, and future tasks return `409 TASK_NOT_OVERDUE`.
- **Skip** is only for recurring tasks; one-time tasks return `409 TASK_NOT_RECURRING`. **Miss** works for both; a missed one-time task is terminal.
- Subtasks do not need to be complete. They keep their state on the closed occurrence.
- For recurring tasks the series continues: if no next occurrence exists, the server creates one with fresh open subtasks. Its date is the latest occurrence already due on or before today (for example, skipping yesterday's daily task leaves today's occurrence); if none, it's the next future occurrence. Existing occurrences are never duplicated.
- **Retries are safe:** repeating the same command on a task that already has that state returns `200` with the current task and changes nothing, even with the original `version`. The original `closeReason` is kept, even if the retry sends different text. A different stale version on an open task returns `409 VERSION_CONFLICT`. Skipping a `MISSED` task (or vice versa), or skipping/missing a `COMPLETED` task, returns `409 TASK_NOT_OPEN`.
- A skipped or missed occurrence cannot be reopened. Completed tasks can still be reopened with `POST /tasks/:taskId/reopen`.

Aggregates: `SKIPPED`/`MISSED` tasks are neither open nor completed. They are excluded from `status=open`, upcoming, overdue, and pending counts. See `dashboard.md` for `skippedCount`, `missedCount`, and completion-rate rules. Project `taskCount`/`progress` exclude skipped tasks (and their subtasks); missed tasks count as not completed.

Postman: `Skip Overdue Recurring Task` and `Miss Overdue Task` in [mymanager_phase_1.postman_collection.json](../../../server/postman/mymanager_phase_1.postman_collection.json). They need `{{taskId}}`/`{{taskVersion}}` for an overdue task.

## Subtask Endpoints

- `POST /tasks/:taskId/subtasks` with `{ "title": "Review copy" }`.
- `PATCH /tasks/:taskId/subtasks/:subtaskId` with `{ "title": "Review final copy", "version": 1 }`.
- `DELETE /tasks/:taskId/subtasks/:subtaskId`.
- `POST /tasks/:taskId/subtasks/:subtaskId/complete` with `{ "version": 1 }`.
- `POST /tasks/:taskId/subtasks/:subtaskId/reopen` with `{ "version": 2 }`.

Adding or changing subtask completion reopens a completed parent. Deleting a task cascades to its subtasks.

Errors: `404 TASK_NOT_FOUND`, `404 PROJECT_NOT_FOUND`, `409 TASK_FUTURE_DATED`, `409 TASK_SUBTASKS_INCOMPLETE`, `409 TASK_NOT_OPEN`, `409 TASK_NOT_OVERDUE`, `409 TASK_NOT_RECURRING`, `409 TASK_NOT_REOPENABLE`, `409 VERSION_CONFLICT`, and `409 SUBTASK_NOT_FOUND_OR_CHANGED`.

## Frontend Integration for Adam

- Replace local task mutation methods in `dashboard_repository.js` and call them from `use_dashboard_controller.js`.
- Map API `completed` directly to current widgets; retain `status`, `version`, `completedAt`, `closedAt`, recurrence, and subtask versions in state.
- Treat a task as open only when `status === "OPEN"`. Render `SKIPPED`/`MISSED` as closed (distinct from completed). Never show them as overdue or pending, and don't offer complete or subtask toggles on them.
- Add `skipTask(taskId, version, reason)` and `missTask(taskId, version, reason)` to `dashboard_repository.js`, orchestrated by `use_dashboard_controller.js`. Skip and Miss each open a small dialog with that action's five preset reasons as quick-pick chips plus a free-text input (max 200, required, Confirm disabled while blank). Show the saved `closeReason` on skipped and missed rows. Show **Skip** only when the task is `OPEN`, recurring (`recurrence.frequency !== "one_time"`), and `dueDate < dashboard.asOfDate`. Show **Miss** when the task is `OPEN` and `dueDate < asOfDate`. Use the server's `asOfDate`, not the browser clock.
- After skip/miss, replace the task from the response and reload `/dashboard`, because a next occurrence and summary counts may have changed. Skipped and missed tasks cannot be reopened.
- Map `409 TASK_NOT_OVERDUE`/`TASK_NOT_RECURRING`/`TASK_NOT_OPEN`/`TASK_NOT_REOPENABLE` to a refresh and a short explanatory toast.
- Keep completion/reopen as command calls rather than generic patch calls. Send the latest version shown by the API.
- On `409 VERSION_CONFLICT`, reload the task/dashboard and tell the user it changed elsewhere.
- Disable duplicate submits while requests are pending. Retain existing delete confirmations and completion error toasts.
- Verify General tasks, blank one-time dates during edit, every recurrence option, future-date rejection, subtask gating, parent reopening, deletion cascades, filters/search, pagination, and repeated recurrence refreshes. Also verify skip/miss visibility rules, double-click/retry without duplicates, skipped/missed tasks cannot be reopened, and summary counts after each action.

## Flutter Integration for Dartji

- Use one tasks feature repository with the shared Dio client; expose typed task/subtask state and actions through GetX controllers, then render with reusable Flutter widgets.
- Implement the listed task and subtask methods exactly. Preserve optional/null `projectId` and `dueDate`, recurrence fields, `version`, `completedAt`, and nested subtasks. A missing create due date means today in the saved server timezone; preserve a blank date when editing an existing undated one-time task.
- For task lists, serialize filters and continue cursor pagination with `cursor=<nextCursor>` until `nextCursor` is null. Do not treat one page as the complete result set.
- Use the dedicated complete/reopen commands, send the latest resource version for versioned mutations, and retain server returned versions. Do not locally allow completion that the contract forbids (future-dated task, incomplete subtasks, `SKIPPED`/`MISSED` status).
- Model `status` as an enum (`OPEN`, `COMPLETED`, `SKIPPED`, `MISSED`) and decode the nullable `closedAt`. Do not infer "open" from `completed == false`.
- Add `skipTask`/`missTask` to the tasks repository and expose them from the GetX controller. Skip and Miss both take a required `reason`: use a bottom sheet with that action's five preset chips plus a text field, and decode the nullable `closeReason`. Use the same visibility rules as Adam, comparing `dueDate` against the dashboard's server `asOfDate` rather than the device clock or device timezone. Disable the buttons while pending, and treat a retried request's `200` as success. After success, reload the dashboard/task list so the new occurrence and counts appear.
- On `409 VERSION_CONFLICT`, reload current server state and explain the conflict. Avoid duplicate submits while pending; show confirmation before destructive deletes and safe error feedback.
- Preserve recurrence materialization and parent/subtask reopening rules on the server; refresh affected aggregate/list data after mutations.
- Verify General tasks, every recurrence option, timezone dates, future-date rejection, completion gating, subtask mutations/parent reopening, deletion cascades, filters/search, cursor pagination, concurrency conflicts, and repeat refresh idempotency. Also verify skip/miss visibility, retry/double-tap idempotency, skipped/missed non-reopenability, and closed-state rendering.