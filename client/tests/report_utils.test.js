import test from "node:test";
import assert from "node:assert/strict";
import { activityCalendar, reportDate, reportRate, reportTimestamp } from "../src/features/reports/report_utils.js";
import { REPORT_YEARS, REPORT_OUTCOMES, REPORT_ACTIVITY } from "../src/features/reports/constants/report_constants.js";

test("null report rates are not zero, including unrated all-skipped populations", () => {
  assert.equal(reportRate(null), "No rated data");
  assert.equal(reportRate(0), "0%");
  assert.equal(reportRate(63), "63%");
});

test("report years cover the exact API range and activity excludes open outcomes", () => {
  assert.equal(REPORT_YEARS.length, 300);
  assert.equal(REPORT_YEARS[0], 2199);
  assert.equal(REPORT_YEARS.at(-1), 1900);
  assert.deepEqual(REPORT_OUTCOMES.map(({ key }) => key), ["completed", "skipped", "missed", "open"]);
  assert.deepEqual(REPORT_ACTIVITY.map(({ key }) => key), ["completed", "skipped", "missed"]);
});

test("heatmap preserves leap years, Monday-first alignment and omitted-day neutrality", () => {
  const months = activityCalendar(2024, [{ date: "2024-02-29", completed: 2, skipped: 1, missed: 4 }]);
  assert.equal(months.length, 12);
  assert.equal(months[0].padding, 0);
  assert.equal(months[1].days.length, 29);
  assert.equal(months.flatMap((month) => month.days).length, 366);
  assert.equal(months[1].days.at(-1).total, 7);
  assert.equal(months[1].days.at(-1).level, 4);
  assert.equal(months[1].days[0].activity, undefined);
  assert.equal(months[1].days[0].total, 0);
  assert.equal(activityCalendar(1900, [])[1].days.length, 28);
  assert.equal(activityCalendar(2000, [])[1].days.length, 29);
});

test("heatmap intensity counts actual timestamp outcomes, not scheduled or inferred tasks", () => {
  const records = [0, 1, 2, 3, 4, 6, 7].map((count, index) => ({ date: `2026-01-0${index + 1}`, completed: count, skipped: 0, missed: 0 }));
  const days = activityCalendar(2026, records)[0].days;
  assert.deepEqual(days.slice(0, 7).map(({ level }) => level), [0, 1, 2, 2, 3, 3, 4]);
  assert.equal(days[7].activity, undefined);
});

test("report due dates remain date-only while snapshot instants use the saved timezone", () => {
  const options = { year: "numeric", month: "2-digit", day: "2-digit" };
  assert.equal(reportDate("2026-01-01", options), new Intl.DateTimeFormat(undefined, { ...options, timeZone: "UTC" }).format(new Date("2026-01-01T12:00:00Z")));
  const instant = "2025-12-31T20:00:00Z";
  assert.equal(reportTimestamp(instant, "Asia/Kolkata"), new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Kolkata" }).format(new Date(instant)));
});
