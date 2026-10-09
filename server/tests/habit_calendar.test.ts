import assert from "node:assert/strict";
import test from "node:test";
import { buildHabitCalendar, monthBounds } from "../src/features/habits/habit_calendar.js";
import { habitCalendarSchema, habitListSchema, habitParamsSchema } from "../src/features/habits/habit_schema.js";
import { habitIdFor, isRecurringHabit, type habitRepository } from "../src/features/habits/habit_repository.js";
import { buildHabitPeriods, habitPeriodUnit } from "../src/features/habits/habit_periods.js";

type Occurrence = Awaited<ReturnType<typeof habitRepository.history>>[number];
function occurrence(day: number, status: Occurrence["status"] = "OPEN"): Occurrence {
  return {
    id: day, title: "Daily habit", dueDate: new Date(`2026-10-${String(day).padStart(2, "0")}T00:00:00Z`),
    status, version: 1, completedAt: null, closedAt: null, closeReason: null,
    recurrenceFrequency: "DAILY", recurrenceInterval: null, recurrenceUnit: null,
  };
}

test("calendar states and exact totals come from recorded due dates, never invented misses", () => {
  const records = [
    { ...occurrence(1, "COMPLETED"), completedAt: new Date("2026-10-05T12:00:00Z") },
    { ...occurrence(2, "SKIPPED"), closeReason: "Rest day" },
    occurrence(3, "MISSED"), occurrence(4), occurrence(9), occurrence(10),
    { ...occurrence(6), recurrenceFrequency: "WEEKLY" as const },
  ];
  const calendar = buildHabitCalendar("2026-10", "2026-10-09", records);
  assert.equal(calendar.days.length, 31);
  assert.deepEqual(calendar.summary, {
    daysInMonth: 31, recordedDays: 7, completedDays: 1, skippedDays: 1, missedDays: 1,
    pendingDays: 1, overdueDays: 2, scheduledDays: 1, notRecordedDays: 24, notDailyDays: 0,
  });
  assert.equal(calendar.days[0].state, "COMPLETED");
  assert.equal(calendar.days[1].occurrence?.closeReason, "Rest day");
  assert.equal(calendar.days[3].state, "OVERDUE");
  assert.equal(calendar.days[4].state, "NOT_RECORDED");
  assert.equal(calendar.days[4].occurrence, null);
  assert.equal(calendar.days[5].state, "OVERDUE");
  assert.equal(calendar.days[8].isToday, true);
  assert.equal(calendar.days[9].state, "SCHEDULED");
});

test("calendar returns real month lengths, leap years, and full empty grids", () => {
  for (const [month, expected] of [["2024-02", 29], ["2025-02", 28], ["2026-04", 30], ["2026-12", 31]] as const) {
    assert.equal(monthBounds(month).daysInMonth, expected);
    const calendar = buildHabitCalendar(month, "2026-10-09", []);
    assert.equal(calendar.days.length, expected);
    assert.equal(calendar.summary.notRecordedDays, expected);
    assert.equal(calendar.summary.recordedDays, 0);
    assert.equal(calendar.days.at(-1)?.date, `${month}-${expected}`);
  }
});

test("all recurring cadences are habits, but one-time tasks are not", () => {
  for (const recurrenceFrequency of ["DAILY", "WEEKLY", "MONTHLY", "YEARLY", "CUSTOM"] as const) {
    assert.equal(isRecurringHabit({ recurrenceFrequency }), true);
  }
  assert.equal(isRecurringHabit({ recurrenceFrequency: "ONE_TIME" }), false);
  assert.equal(habitIdFor({ id: 1, recurrenceSeriesId: "series" }), "series");
  assert.equal(habitIdFor({ id: 1, recurrenceSeriesId: null }), "task-1");
});

test("weekly history groups Monday-Sunday without fabricating empty periods or merging outcomes", () => {
  const data = [occurrence(1, "COMPLETED"), occurrence(2, "SKIPPED"), occurrence(15, "MISSED")];
  const history = buildHabitPeriods(2026, "2026-10-09", "week", data);
  assert.equal(history.periods.length, 2);
  assert.equal(history.periods[0].startDate, "2026-09-28");
  assert.equal(history.periods[0].endDate, "2026-10-04");
  assert.equal(history.periods[0].summary.completedOccurrences, 1);
  assert.equal(history.periods[0].summary.skippedOccurrences, 1);
  assert.equal(history.summary.recordedOccurrences, 3);
});

test("monthly/yearly/custom history keeps exact dates and year-boundary periods", () => {
  const data = [occurrence(1, "COMPLETED"), occurrence(15)];
  assert.equal(buildHabitPeriods(2026, "2026-10-09", "month", data).periods[0].endDate, "2026-10-31");
  const yearly = buildHabitPeriods(2026, "2026-10-09", "year", data);
  assert.equal(yearly.periods[0].startDate, "2026-01-01");
  assert.equal(yearly.periods[0].endDate, "2026-12-31");
  assert.equal(yearly.periods[0].summary.scheduledOccurrences, 1);
  assert.deepEqual(buildHabitPeriods(2026, "2026-10-09", "year", []).periods, []);
  assert.equal(habitPeriodUnit({ recurrenceFrequency: "CUSTOM", recurrenceInterval: 3, recurrenceUnit: "MONTH" }), "month");
  const january = { ...occurrence(1), dueDate: new Date("2027-01-01T00:00:00Z") };
  const week = buildHabitPeriods(2027, "2026-10-09", "week", [january]).periods[0];
  assert.equal(week.startDate, "2026-12-28");
  assert.equal(week.endDate, "2027-01-03");
});

test("habit boundary rejects invalid months, identifiers and unbounded list queries", () => {
  assert.equal(habitCalendarSchema.parse({}).month, undefined);
  assert.equal(habitCalendarSchema.safeParse({ month: "2024-02" }).success, true);
  for (const month of ["2026-00", "2026-13", "2026-1", "2026-10-09", "0000-01", "2200-01"]) {
    assert.equal(habitCalendarSchema.safeParse({ month }).success, false);
  }
  assert.equal(habitListSchema.parse({}).limit, 50);
  for (const limit of ["0", "101", "1.5", "not-a-number"]) {
    assert.equal(habitListSchema.safeParse({ limit }).success, false);
  }
  assert.equal(habitListSchema.safeParse({ projectId: "1", search: " walk " }).success, true);
  assert.equal(habitListSchema.safeParse({ unexpected: true }).success, false);
  assert.equal(habitParamsSchema.safeParse({ habitId: "task-12" }).success, true);
  assert.equal(habitParamsSchema.safeParse({ habitId: "task-9999999999" }).success, false);
  assert.equal(habitParamsSchema.safeParse({ habitId: "not-a-habit" }).success, false);
});
