import assert from "node:assert/strict";
import test from "node:test";
import { calendarPadding, formatHabitDate, formatHabitTimestamp, shiftHabitMonth } from "../src/features/habits/habit_calendar_utils.js";

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
