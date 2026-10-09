import { recurrenceFromTask } from "../tasks/task_service.js";
import { buildHabitCalendar } from "./habit_calendar.js";
import type { HabitTask, habitRepository } from "./habit_repository.js";

export type HabitPeriodUnit = "day" | "week" | "month" | "year";

export function habitPeriodUnit(task: Pick<HabitTask, "recurrenceFrequency" | "recurrenceInterval" | "recurrenceUnit">): HabitPeriodUnit {
  const rule = recurrenceFromTask(task);
  if (rule.frequency === "weekly") return "week";
  if (rule.frequency === "monthly") return "month";
  if (rule.frequency === "yearly") return "year";
  return rule.unit ?? "day";
}

function periodBounds(date: string, unit: HabitPeriodUnit) {
  const start = new Date(`${date}T00:00:00Z`);
  const end = new Date(start);
  if (unit === "week") {
    start.setUTCDate(start.getUTCDate() - (start.getUTCDay() + 6) % 7);
    end.setTime(start.getTime());
    end.setUTCDate(end.getUTCDate() + 6);
  } else if (unit === "month") {
    start.setUTCDate(1);
    end.setUTCMonth(end.getUTCMonth() + 1, 0);
  } else if (unit === "year") {
    start.setUTCMonth(0, 1);
    end.setUTCMonth(11, 31);
  }
  return { startDate: start.toISOString().slice(0, 10), endDate: end.toISOString().slice(0, 10) };
}

export function buildHabitPeriods(
  year: number, today: string, unit: HabitPeriodUnit,
  occurrences: Awaited<ReturnType<typeof habitRepository.history>>,
) {
  const entries = Array.from({ length: 12 }, (_, index) =>
    buildHabitCalendar(`${year}-${String(index + 1).padStart(2, "0")}`, today, occurrences).days
  ).flat().filter((day) => day.occurrence !== null);
  const groups = new Map<string, {
    startDate: string; endDate: string; occurrences: typeof entries;
  }>();
  for (const entry of entries) {
    const bounds = periodBounds(entry.date, unit);
    let group = groups.get(bounds.startDate);
    if (!group) {
      group = { ...bounds, occurrences: [] };
      groups.set(bounds.startDate, group);
    }
    group.occurrences.push(entry);
  }
  const counts = (days: typeof entries) => ({
    recordedOccurrences: days.length,
    completedOccurrences: days.filter((day) => day.state === "COMPLETED").length,
    skippedOccurrences: days.filter((day) => day.state === "SKIPPED").length,
    missedOccurrences: days.filter((day) => day.state === "MISSED").length,
    pendingOccurrences: days.filter((day) => day.state === "PENDING").length,
    overdueOccurrences: days.filter((day) => day.state === "OVERDUE").length,
    scheduledOccurrences: days.filter((day) => day.state === "SCHEDULED").length,
    nonRecurringOccurrences: days.filter((day) => day.state === "NOT_DAILY").length,
  });
  return {
    periodUnit: unit, summary: counts(entries),
    periods: [...groups.values()].map((group) => ({ ...group, summary: counts(group.occurrences) })),
  };
}
