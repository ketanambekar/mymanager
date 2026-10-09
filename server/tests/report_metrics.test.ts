import assert from "node:assert/strict";
import test from "node:test";
import { buildReportMetrics, outcomeCounts } from "../src/features/reports/report_metrics.js";
import type { ReportTask } from "../src/features/reports/report_repository.js";
import { reportQuerySchema } from "../src/features/reports/report_schema.js";

function task(id: number, changes: Partial<ReportTask> = {}): ReportTask {
  return {
    id, title: "Report fixture", projectId: null, status: "OPEN",
    dueDate: new Date("2026-01-01"), completedAt: null, closedAt: null, closeReason: null,
    recurrenceSeriesId: null, recurrenceFrequency: "ONE_TIME", recurrenceInterval: null,
    recurrenceUnit: null, occurrenceNumber: 1, ...changes,
  };
}

test("report ratios exclude skips, retain misses, and return null for no rated data", () => {
  assert.equal(outcomeCounts([]).completionRate, null);
  assert.equal(outcomeCounts([{ status: "SKIPPED", count: 4 }]).completionRate, null);
  assert.deepEqual(outcomeCounts([
    { status: "COMPLETED", count: 2 }, { status: "SKIPPED", count: 1 },
    { status: "MISSED", count: 1 }, { status: "OPEN", count: 1 },
  ]), { total: 5, completed: 2, skipped: 1, missed: 1, open: 1, rated: 4, completionRate: 50 });
});

test("due cohorts and local activity dates stay distinct across year boundaries", () => {
  const metrics = buildReportMetrics([
    task(1, { status: "COMPLETED", completedAt: new Date("2025-12-31T12:00:00Z") }),
    task(2, { status: "COMPLETED", completedAt: new Date("2026-01-03T00:00:00Z") }),
    task(3, { status: "COMPLETED" }),
    task(4, { status: "SKIPPED", closedAt: new Date("2026-01-02"), closeReason: "Rest", recurrenceFrequency: "WEEKLY", recurrenceSeriesId: "series" }),
    task(5, { dueDate: new Date("2025-12-01"), status: "COMPLETED", completedAt: new Date("2026-01-05") }),
    task(6, { dueDate: null, status: "MISSED", closedAt: new Date("2026-01-06") }),
  ], 2026, "Pacific/Kiritimati", "2026-10-09");
  assert.equal(metrics.dueSummary.total, 4);
  assert.equal(metrics.dueSummary.onTimeCompleted, 1);
  assert.equal(metrics.dueSummary.lateCompleted, 1);
  assert.equal(metrics.dueSummary.completionTimingUnknown, 1);
  assert.equal(metrics.dueSummary.onTimeRate, 50);
  assert.deepEqual(metrics.activitySummary, { completed: 3, skipped: 1, missed: 1 });
  assert.equal(metrics.activityDays[0].date, "2026-01-01");
  assert.equal(metrics.monthly.length, 12);
  assert.equal(metrics.monthly[1].due.completionRate, null);
  assert.equal(metrics.recurringSummary.seriesCount, 1);
  assert.equal(metrics.reasons.items[0].reason, "Rest");
});

test("reports preserve recorded status and bounded ranked results without imaginary activity", () => {
  const rows = Array.from({ length: 25 }, (_, i) => task(i, {
    recurrenceFrequency: "CUSTOM", recurrenceInterval: 2, recurrenceUnit: "MONTH",
    recurrenceSeriesId: `series-${i}`, status: "COMPLETED",
  }));
  const report = buildReportMetrics(rows, 2026, "UTC", "2026-10-09");
  assert.equal(report.habits.items.length, 10);
  assert.equal(report.habits.totalSeries, 25);
  assert.equal(report.activityDays.length, 0);
  assert.equal(report.dueSummary.completionTimingUnknown, 25);
  assert.deepEqual(buildReportMetrics([], 2026, "UTC", "2026-10-09").activityDays, []);
  for (const year of [0, 2200, 2026.5, "bad"]) assert.equal(reportQuerySchema.safeParse({ year }).success, false);
  assert.equal(reportQuerySchema.safeParse({ unexpected: 1 }).success, false);
});
