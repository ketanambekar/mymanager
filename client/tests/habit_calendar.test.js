import assert from "node:assert/strict";
import test from "node:test";
import { adjacentHabitMonths, adjacentHabitYears, calendarPadding, formatHabitDate, formatHabitPeriod, formatHabitTimestamp, habitHistoryYears, isHabitHistoryDate, nearestHabitMonth, shiftHabitMonth } from "../src/features/habits/habit_calendar_utils.js";

test("month navigation crosses years without changing calendar dates", () => {
  assert.equal(shiftHabitMonth("2026-01", -1), "2025-12");
  assert.equal(shiftHabitMonth("2026-12", 1), "2027-01");
  assert.equal(shiftHabitMonth("2024-03", -1), "2024-02");
});

test("calendar padding preserves 28, 29, 30 and 31 actual days", () => {
  for (const [month, count] of [["2023-02", 28], ["2024-02", 29], ["2026-04", 30], ["2026-10", 31]]) {
    const days = Array.from({ length: count }, (_, index) => ({ date: `${month}-${String(index + 1).padStart(2, "0")}` }));
    const { leading, trailing } = calendarPadding(days);
    assert.equal((leading + days.length + trailing) % 7, 0);
    assert(leading >= 0 && leading <= 6);
    assert(trailing >= 0 && trailing <= 6);
    assert.equal(days.length, count);
  }
});

test("calendar uses Monday-first alignment", () => {
  assert.deepEqual(calendarPadding([{ date: "2026-10-01" }]), { leading: 3, trailing: 3 });
  assert.deepEqual(calendarPadding([{ date: "2026-10-05" }]), { leading: 0, trailing: 6 });
  assert.deepEqual(calendarPadding([{ date: "2026-10-04" }]), { leading: 6, trailing: 0 });
});

test("date-only labels never shift into another day", () => {
  assert.equal(formatHabitDate("2026-10-01"), "1 October 2026");
  assert.equal(formatHabitDate("2024-02-29"), "29 February 2024");
  assert.equal(formatHabitDate("1900-01-01"), "1 January 1900");
  assert.equal(formatHabitDate("2199-12-31"), "31 December 2199");
});

test("timestamps use the server-provided timezone, not the due date", () => {
  assert.equal(formatHabitTimestamp("2026-10-05T14:20:00.000Z", "Asia/Kolkata"), "5 Oct 2026, 19:50:00");
  assert.equal(formatHabitTimestamp("2026-10-01T00:30:00.000Z", "America/Los_Angeles"), "30 Sept 2026, 17:30:00");
});

test("nearest populated month uses month distance and earlier tie, including future history", () => {
  assert.equal(nearestHabitMonth(["2026-09", "2026-11"], "2026-10"), "2026-09");
  assert.equal(nearestHabitMonth(["2025-12", "2026-02"], "2026-01"), "2025-12");
  assert.equal(nearestHabitMonth(["2024-02", "2026-06", "2026-08", "2099-12"], "2026-10"), "2026-08");
  assert.equal(nearestHabitMonth(["2099-12"], "2026-10"), "2099-12");
  assert.equal(nearestHabitMonth([], "2026-10"), null);
});

test("previous and next skip empty months and disable at endpoints", () => {
  const months = ["2024-02", "2026-08", "2099-12"];
  assert.deepEqual(adjacentHabitMonths(months, "2026-08"), { previous: "2024-02", next: "2099-12" });
  assert.deepEqual(adjacentHabitMonths(months, "2024-02"), { previous: null, next: "2026-08" });
  assert.deepEqual(adjacentHabitMonths(months, "2099-12"), { previous: "2026-08", next: null });
  assert.deepEqual(adjacentHabitMonths(months, "2026-10"), { previous: "2026-08", next: "2099-12" });
  assert.deepEqual(adjacentHabitMonths([], "2026-10"), { previous: null, next: null });
});

test("history bounds hide only external dates, not interior missing or future dates", () => {
  const calendar = { firstRecordedDate: "2024-02-29", lastRecordedDate: "2099-12-20", latestOccurrence: { dueDate: "2026-06-01" } };
  assert(!isHabitHistoryDate("2024-02-28", calendar));
  assert(isHabitHistoryDate("2024-02-29", calendar));
  assert(isHabitHistoryDate("2026-10-03", calendar));
  assert(isHabitHistoryDate("2099-12-20", calendar));
  assert(!isHabitHistoryDate("2099-12-21", calendar));
  assert(!isHabitHistoryDate("2026-10-09", { firstRecordedDate: null, lastRecordedDate: null }));
});

test("period history year navigation deduplicates years and skips empty years", () => {
  const months = ["2024-02", "2026-06", "2026-08", "2099-12"];
  assert.deepEqual(habitHistoryYears(months), [2024, 2026, 2099]);
  assert.deepEqual(adjacentHabitYears(months, 2026), { previous: 2024, next: 2099 });
  assert.deepEqual(adjacentHabitYears(months, 2024), { previous: null, next: 2026 });
  assert.deepEqual(adjacentHabitYears(months, 2099), { previous: 2026, next: null });
  assert.deepEqual(adjacentHabitYears([], 2026), { previous: null, next: null });
});

test("period labels preserve cross-year weeks and month/year presentation", () => {
  const period = { startDate: "2025-12-29", endDate: "2026-01-04" };
  assert.equal(formatHabitPeriod(period, "week"), "29 Dec 2025 - 4 Jan 2026");
  assert.equal(formatHabitPeriod({ startDate: "2026-10-01" }, "month"), "October 2026");
  assert.equal(formatHabitPeriod({ startDate: "2026-01-01" }, "year"), "2026");
});
