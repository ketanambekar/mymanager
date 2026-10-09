import { isDailyHabit, type habitRepository } from "./habit_repository.js";

type Occurrence = Awaited<ReturnType<typeof habitRepository.history>>[number];
export type HabitDayState = "COMPLETED" | "SKIPPED" | "MISSED" | "PENDING" | "OVERDUE" | "SCHEDULED" | "NOT_RECORDED" | "NOT_DAILY";

export function monthBounds(month: string) {
  const start = new Date(`${month}-01T00:00:00.000Z`);
  const end = new Date(start);
  end.setUTCMonth(end.getUTCMonth() + 1);
  return { start, end, daysInMonth: (end.getTime() - start.getTime()) / 86400000 };
}

function dayState(task: Occurrence, date: string, today: string): HabitDayState {
  if (!isDailyHabit(task)) return "NOT_DAILY";
  if (task.status !== "OPEN") return task.status;
  return date < today ? "OVERDUE" : date === today ? "PENDING" : "SCHEDULED";
}

export function buildHabitCalendar(month: string, today: string, occurrences: Occurrence[]) {
  const { daysInMonth } = monthBounds(month);
  const byDate = new Map(occurrences.map((task) => [task.dueDate?.toISOString().slice(0, 10), task]));
  const counts: Record<HabitDayState, number> = {
    COMPLETED: 0, SKIPPED: 0, MISSED: 0, PENDING: 0, OVERDUE: 0, SCHEDULED: 0, NOT_RECORDED: 0, NOT_DAILY: 0,
  };
  const days = Array.from({ length: daysInMonth }, (_, index) => {
    const date = `${month}-${String(index + 1).padStart(2, "0")}`;
    const task = byDate.get(date);
    const state = task ? dayState(task, date, today) : "NOT_RECORDED";
    counts[state] += 1;
    return {
      date, state, isToday: date === today,
      occurrence: task ? {
        taskId: task.id, title: task.title, status: task.status, version: task.version,
        completedAt: task.completedAt, closedAt: task.closedAt, closeReason: task.closeReason,
      } : null,
    };
  });
  return {
    days,
    summary: {
      daysInMonth, recordedDays: daysInMonth - counts.NOT_RECORDED,
      completedDays: counts.COMPLETED, skippedDays: counts.SKIPPED, missedDays: counts.MISSED,
      pendingDays: counts.PENDING, overdueDays: counts.OVERDUE, scheduledDays: counts.SCHEDULED,
      notRecordedDays: counts.NOT_RECORDED, notDailyDays: counts.NOT_DAILY,
    },
  };
}
