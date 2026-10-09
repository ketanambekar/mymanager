import { prisma } from "../../database/prisma.js";
import { AppError } from "../../shared/app_error.js";
import { dateInTimeZone } from "../tasks/recurrence.js";
import { buildHabitCalendar, monthBounds } from "./habit_calendar.js";
import { habitIdFor, habitRepository, habitSnapshot, isDailyHabit, type HabitTask } from "./habit_repository.js";
import type { HabitListInput } from "./habit_schema.js";

function habitView(task: HabitTask) {
  return {
    id: habitIdFor(task), title: task.title, project: task.project,
    latestOccurrence: {
      taskId: task.id, dueDate: task.dueDate?.toISOString().slice(0, 10) ?? null,
      status: task.status, version: task.version,
    },
  };
}

async function calendarContext(userId: number) {
  const preference = await prisma.userPreference.findUnique({ where: { userId }, select: { timezone: true } });
  if (!preference) throw new AppError("PREFERENCES_NOT_FOUND", "User preferences not found", 404);
  return { timezone: preference.timezone, asOfDate: dateInTimeZone(new Date(), preference.timezone) };
}

export const habitService = {
  async list(userId: number, workspaceId: number, input: HabitListInput) {
    const context = await calendarContext(userId);
    return habitSnapshot(async (db) => {
      const tasks = await habitRepository.list(db, workspaceId, input);
      const hasMore = tasks.length > input.limit;
      const page = tasks.slice(0, input.limit);
      return {
        ...context, items: page.map(habitView),
        nextCursor: hasMore ? habitIdFor(page[page.length - 1]) : null,
      };
    });
  },
  async calendar(userId: number, workspaceId: number, habitId: string, requestedMonth?: string) {
    const context = await calendarContext(userId);
    const month = requestedMonth ?? context.asOfDate.slice(0, 7);
    const { start, end } = monthBounds(month);
    return habitSnapshot(async (db) => {
      const task = await habitRepository.latest(db, workspaceId, habitId);
      if (!task || !isDailyHabit(task)) throw new AppError("HABIT_NOT_FOUND", "Daily habit not found", 404);
      const [occurrences, coverage, undatedOccurrencesCount] = await Promise.all([
        habitRepository.history(db, workspaceId, habitId, start, end),
        habitRepository.coverage(db, workspaceId, habitId),
        habitRepository.undatedCount(db, workspaceId, habitId),
      ]);
      return {
        ...context, month, habit: habitView(task),
        firstRecordedDueDate: coverage._min.dueDate?.toISOString().slice(0, 10) ?? null,
        undatedOccurrencesCount, ...buildHabitCalendar(month, context.asOfDate, occurrences),
      };
    });
  },
};
