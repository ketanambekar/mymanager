import assert from "node:assert/strict";
import test from "node:test";
import { TaskStatus } from "@prisma/client";
import { followingOccurrenceDate } from "../src/features/tasks/recurrence.js";
import { assertCanReopen, closureOutcome } from "../src/features/tasks/task_closure.js";
import { missTaskSchema, skipTaskSchema } from "../src/features/tasks/task_schema.js";

const today = "2026-10-05";
const overdueRecurring = { status: TaskStatus.OPEN, dueDate: "2026-10-01", recurring: true };

function errorCode(action: () => unknown): string | undefined {
  try {
    action();
  } catch (error) {
    return (error as { code?: string }).code;
  }
  return undefined;
}

test("overdue recurring tasks can be skipped or missed", () => {
  assert.equal(closureOutcome(overdueRecurring, "skip", today), "apply");
  assert.equal(closureOutcome(overdueRecurring, "miss", today), "apply");
});

test("one-time overdue tasks can be missed but not skipped", () => {
  const task = { ...overdueRecurring, recurring: false };
  assert.equal(closureOutcome(task, "miss", today), "apply");
  assert.equal(errorCode(() => closureOutcome(task, "skip", today)), "TASK_NOT_RECURRING");
});

test("tasks due today, in the future, or undated are not overdue", () => {
  for (const dueDate of [today, "2026-10-06", null]) {
    assert.equal(errorCode(() => closureOutcome({ ...overdueRecurring, dueDate }, "miss", today)), "TASK_NOT_OVERDUE");
  }
});

test("repeating the same action is a replay, not an error", () => {
  assert.equal(closureOutcome({ ...overdueRecurring, status: TaskStatus.SKIPPED }, "skip", today), "replay");
  assert.equal(closureOutcome({ ...overdueRecurring, status: TaskStatus.MISSED }, "miss", today), "replay");
});

test("completed or differently closed tasks cannot be skipped or missed", () => {
  assert.equal(errorCode(() => closureOutcome({ ...overdueRecurring, status: TaskStatus.COMPLETED }, "skip", today)), "TASK_NOT_OPEN");
  assert.equal(errorCode(() => closureOutcome({ ...overdueRecurring, status: TaskStatus.SKIPPED }, "miss", today)), "TASK_NOT_OPEN");
});

test("skipped and missed tasks cannot be reopened", () => {
  assert.equal(errorCode(() => assertCanReopen(TaskStatus.SKIPPED)), "TASK_NOT_REOPENABLE");
  assert.equal(errorCode(() => assertCanReopen(TaskStatus.MISSED)), "TASK_NOT_REOPENABLE");
  assert.equal(assertCanReopen(TaskStatus.COMPLETED), undefined);
});

test("closing an overdue daily task continues with today's occurrence", () => {
  assert.equal(followingOccurrenceDate("2026-10-03", { frequency: "daily" }, today), today);
});

test("closing an overdue weekly task continues with the next future occurrence", () => {
  assert.equal(followingOccurrenceDate("2026-10-01", { frequency: "weekly" }, today), "2026-10-08");
});

test("skip and miss require a trimmed reason of 1-200 characters", () => {
  for (const schema of [skipTaskSchema, missTaskSchema]) {
    assert.deepEqual(schema.parse({ version: 2, reason: "  Rest day  " }), { version: 2, reason: "Rest day" });
    for (const body of [{ version: 2 }, { version: 2, reason: "   " }, { version: 2, reason: "x".repeat(201) }, { version: 2, reason: "ok", extra: true }]) {
      assert.equal(schema.safeParse(body).success, false);
    }
  }
});
