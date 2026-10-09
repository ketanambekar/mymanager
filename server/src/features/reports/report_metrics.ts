import type { TaskStatus } from "@prisma/client";
import { dateInTimeZone } from "../tasks/recurrence.js";
import { recurrenceFromTask } from "../tasks/task_service.js";
import type { ReportTask } from "./report_repository.js";

export function outcomeCounts(rows: Array<{ status: TaskStatus; count: number }>) {
  const count = (status: TaskStatus) => rows.filter((row) => row.status === status).reduce((sum, row) => sum + row.count, 0);
  const completed = count("COMPLETED"), skipped = count("SKIPPED"), missed = count("MISSED"), open = count("OPEN");
  const total = completed + skipped + missed + open;
  const rated = total - skipped;
  return { total, completed, skipped, missed, open, rated, completionRate: rated ? Math.round(completed / rated * 100) : null };
}

export function buildReportMetrics(tasks: ReportTask[], year: number, timezone: string, today: string) {
  const yearString = String(year);
  const dueTasks = tasks.filter((task): task is ReportTask & { dueDate: Date } =>
    task.dueDate !== null && task.dueDate.toISOString().startsWith(`${yearString}-`));
  const outcomes = (items: ReportTask[]) => outcomeCounts(items.map((task) => ({ status: task.status, count: 1 })));
  const activityDate = (task: ReportTask) => {
    const timestamp = task.status === "COMPLETED" ? task.completedAt
      : task.status === "SKIPPED" || task.status === "MISSED" ? task.closedAt : null;
    return timestamp ? dateInTimeZone(timestamp, timezone) : null;
  };
  const activity = tasks.map((task) => ({ task, date: activityDate(task) }))
    .filter((entry) => entry.date?.startsWith(`${yearString}-`));
  const activityCounts = (entries: typeof activity) => ({
    completed: entries.filter((entry) => entry.task.status === "COMPLETED").length,
    skipped: entries.filter((entry) => entry.task.status === "SKIPPED").length,
    missed: entries.filter((entry) => entry.task.status === "MISSED").length,
  });
  const daily = new Map<string, typeof activity>();
  for (const entry of activity) {
    if (entry.date) daily.set(entry.date, [...(daily.get(entry.date) ?? []), entry]);
  }
  const series = new Map<string, ReportTask[]>();
  for (const task of dueTasks) {
    if (task.recurrenceFrequency === "ONE_TIME") continue;
    const id = task.recurrenceSeriesId ?? `task-${task.id}`;
    series.set(id, [...(series.get(id) ?? []), task]);
  }
  const habits = [...series].map(([id, occurrences]) => {
    const latest = [...occurrences].sort((a, b) => b.occurrenceNumber - a.occurrenceNumber || b.id - a.id)[0];
    return { id, title: latest.title, recurrence: recurrenceFromTask(latest), ...outcomes(occurrences) };
  }).sort((a, b) => b.completed - a.completed || a.id.localeCompare(b.id));
  const onTime = dueTasks.filter((task) => task.status === "COMPLETED" && task.completedAt !== null
    && dateInTimeZone(task.completedAt, timezone) <= task.dueDate.toISOString().slice(0, 10)).length;
  const timedCompleted = dueTasks.filter((task) => task.status === "COMPLETED" && task.completedAt).length;
  const reasonCounts = new Map<string, { status: "SKIPPED" | "MISSED"; reason: string; count: number }>();
  for (const task of dueTasks) {
    if ((task.status !== "SKIPPED" && task.status !== "MISSED") || !task.closeReason) continue;
    const key = `${task.status}:${task.closeReason}`;
    const entry = reasonCounts.get(key) ?? { status: task.status, reason: task.closeReason, count: 0 };
    entry.count += 1;
    reasonCounts.set(key, entry);
  }
  return {
    dueSummary: {
      ...outcomes(dueTasks), overdue: dueTasks.filter((task) => task.status === "OPEN" && task.dueDate.toISOString().slice(0, 10) < today).length,
      onTimeCompleted: onTime, lateCompleted: timedCompleted - onTime,
      completionTimingUnknown: dueTasks.filter((task) => task.status === "COMPLETED" && !task.completedAt).length,
      onTimeRate: timedCompleted ? Math.round(onTime / timedCompleted * 100) : null,
    },
    activitySummary: activityCounts(activity),
    monthly: Array.from({ length: 12 }, (_, index) => {
      const month = `${year}-${String(index + 1).padStart(2, "0")}`;
      return {
        month, due: outcomes(dueTasks.filter((task) => task.dueDate.toISOString().startsWith(month))),
        activity: activityCounts(activity.filter((entry) => entry.date?.startsWith(month))),
      };
    }),
    activityDays: [...daily].sort(([a], [b]) => a.localeCompare(b)).map(([date, entries]) => ({ date, ...activityCounts(entries) })),
    recurringSummary: { seriesCount: habits.length, ...outcomes(dueTasks.filter((task) => task.recurrenceFrequency !== "ONE_TIME")) },
    habits: { items: habits.slice(0, 10), totalSeries: habits.length, limit: 10 },
    reasons: { items: [...reasonCounts.values()].sort((a, b) => b.count - a.count || a.reason.localeCompare(b.reason)).slice(0, 10), totalReasons: reasonCounts.size, limit: 10 },
  };
}
