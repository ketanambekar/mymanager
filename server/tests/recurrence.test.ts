import assert from "node:assert/strict";
import test from "node:test";
import { latestOccurrenceDate, nextOccurrenceDate } from "../src/features/tasks/recurrence.js";

test("daily recurrence advances beyond the comparison date", () => {
  assert.equal(nextOccurrenceDate("2026-09-01", { frequency: "daily" }, "2026-09-30"), "2026-10-01");
});

test("custom weekly recurrence respects its interval", () => {
  assert.equal(nextOccurrenceDate("2026-09-01", { frequency: "custom", interval: 2, unit: "week" }, "2026-09-01"), "2026-09-15");
});

test("monthly recurrence clamps to the target month end", () => {
  assert.equal(nextOccurrenceDate("2026-01-31", { frequency: "monthly" }, "2026-01-31"), "2026-02-28");
});

test("yearly recurrence clamps leap day", () => {
  assert.equal(nextOccurrenceDate("2024-02-29", { frequency: "yearly" }, "2024-02-29"), "2025-02-28");
});

test("overdue catch-up returns only the latest due occurrence", () => {
  assert.equal(latestOccurrenceDate("2026-09-01", { frequency: "weekly" }, "2026-09-30"), "2026-09-29");
});

test("one-time tasks never create another occurrence", () => {
  assert.equal(nextOccurrenceDate("2026-09-01", { frequency: "one_time" }, "2026-09-30"), null);
});