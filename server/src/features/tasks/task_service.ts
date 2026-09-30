import crypto from "node:crypto";
import { Prisma, RecurrenceFrequency, RecurrenceUnit, TaskStatus } from "@prisma/client";
import { prisma } from "../../database/prisma.js";
import { AppError } from "../../shared/app_error.js";
import { dateInTimeZone, latestOccurrenceDate, nextOccurrenceDate, type RecurrenceRule } from "./recurrence.js";
import { taskInclude, taskRepository } from "./task_repository.js";

type RecurrenceInput = RecurrenceRule;
type TaskInput = { title: string; projectId?: number | null; dueDate?: string | null; recurrence?: RecurrenceInput };
type TaskUpdate = Partial<TaskInput> & { version: number };
type ListInput = { status: "all" | "open" | "completed"; projectId?: number; search?: string; dateScope: "recent" | "upcoming" | "all"; cursor?: number; limit: number };

const frequencyToDb: Record<RecurrenceRule["frequency"], RecurrenceFrequency> = {
  one_time: RecurrenceFrequency.ONE_TIME,
  daily: RecurrenceFrequency.DAILY,
  weekly: RecurrenceFrequency.WEEKLY,
  monthly: RecurrenceFrequency.MONTHLY,
  yearly: RecurrenceFrequency.YEARLY,
  custom: RecurrenceFrequency.CUSTOM,
};
const frequencyFromDb: Record<RecurrenceFrequency, RecurrenceRule["frequency"]> = {
  ONE_TIME: "one_time", DAILY: "daily", WEEKLY: "weekly", MONTHLY: "monthly", YEARLY: "yearly", CUSTOM: "custom",
};
const unitToDb = { day: RecurrenceUnit.DAY, week: RecurrenceUnit.WEEK, month: RecurrenceUnit.MONTH, year: RecurrenceUnit.YEAR } as const;
const unitFromDb = { DAY: "day", WEEK: "week", MONTH: "month", YEAR: "year" } as const;

function asDatabaseDate(value: string | null | undefined): Date | null {
  return value ? new Date(`${value}T00:00:00.000Z`) : null;
}

function asDateString(value: Date | null): string | null {
  return value?.toISOString().slice(0, 10) ?? null;
}

function recurrenceFromTask(task: { recurrenceFrequency: RecurrenceFrequency; recurrenceInterval: number | null; recurrenceUnit: RecurrenceUnit | null }): RecurrenceRule {
  return { frequency: frequencyFromDb[task.recurrenceFrequency], interval: task.recurrenceInterval, unit: task.recurrenceUnit ? unitFromDb[task.recurrenceUnit] : null };
}

export function taskView<T extends { dueDate: Date | null; status: TaskStatus; completedAt: Date | null; recurrenceFrequency: RecurrenceFrequency; recurrenceInterval: number | null; recurrenceUnit: RecurrenceUnit | null; subtasks: Array<{ status: TaskStatus; completedAt: Date | null }> }>(task: T) {
  return {
    ...task,
    dueDate: asDateString(task.dueDate),
    completed: task.status === TaskStatus.COMPLETED,
    recurrence: recurrenceFromTask(task),
    subtasks: task.subtasks.map((subtask) => ({ ...subtask, completed: subtask.status === TaskStatus.COMPLETED })),
  };
}

async function timezoneForUser(userId: number): Promise<string> {
  return (await prisma.userPreference.findUnique({ where: { userId }, select: { timezone: true } }))?.timezone ?? "UTC";
}

async function validateProject(workspaceId: number, projectId: number | null | undefined): Promise<void> {
  if (!projectId) return;
  if (!await prisma.project.findFirst({ where: { id: projectId, workspaceId }, select: { id: true } })) throw new AppError("PROJECT_NOT_FOUND", "Project not found", 404);
}

function recurrenceData(rule: RecurrenceInput | undefined) {
  const value = rule ?? { frequency: "one_time" as const };
  return {
    recurrenceFrequency: frequencyToDb[value.frequency],
    recurrenceInterval: value.frequency === "custom" ? value.interval : null,
    recurrenceUnit: value.frequency === "custom" && value.unit ? unitToDb[value.unit] : null,
  };
}

export const taskService = {
  async list(userId: number, workspaceId: number, input: ListInput) {
    const today = dateInTimeZone(new Date(), await timezoneForUser(userId));
    const dateFilter = input.dateScope === "recent" ? { OR: [{ dueDate: null }, { dueDate: { lte: asDatabaseDate(today)! } }] }
      : input.dateScope === "upcoming" ? { dueDate: { gt: asDatabaseDate(today)! }, status: TaskStatus.OPEN }
        : {};
    const tasks = await prisma.task.findMany({
      where: {
        workspaceId,
        id: input.cursor ? { lt: input.cursor } : undefined,
        projectId: input.projectId,
        status: input.status === "all" ? undefined : input.status === "open" ? TaskStatus.OPEN : TaskStatus.COMPLETED,
        title: input.search ? { contains: input.search } : undefined,
        ...dateFilter,
      },
      include: taskInclude,
      orderBy: { id: "desc" },
      take: input.limit + 1,
    });
    const hasMore = tasks.length > input.limit;
    const page = hasMore ? tasks.slice(0, input.limit) : tasks;
    return { items: page.map(taskView), nextCursor: hasMore ? page.at(-1)?.id ?? null : null };
  },

  async get(workspaceId: number, id: number) {
    const task = await taskRepository.find(workspaceId, id);
    if (!task) throw new AppError("TASK_NOT_FOUND", "Task not found", 404);
    return taskView(task);
  },

  async create(userId: number, workspaceId: number, input: TaskInput) {
    await validateProject(workspaceId, input.projectId);
    const timezone = await timezoneForUser(userId);
    const rule = input.recurrence ?? { frequency: "one_time" as const };
    const dueDate = input.dueDate ?? dateInTimeZone(new Date(), timezone);
    const task = await prisma.task.create({
      data: {
        workspaceId,
        projectId: input.projectId ?? null,
        title: input.title,
        dueDate: asDatabaseDate(dueDate),
        ...recurrenceData(rule),
        recurrenceSeriesId: rule.frequency === "one_time" ? null : crypto.randomUUID(),
      },
      include: taskInclude,
    });
    return taskView(task);
  },

  async update(workspaceId: number, id: number, input: TaskUpdate) {
    const current = await taskRepository.find(workspaceId, id);
    if (!current) throw new AppError("TASK_NOT_FOUND", "Task not found", 404);
    if (current.version !== input.version) throw new AppError("VERSION_CONFLICT", "Task changed since it was loaded", 409);
    await validateProject(workspaceId, input.projectId);
    const recurrence = input.recurrence ? recurrenceData(input.recurrence) : {};
    const seriesId = input.recurrence
      ? input.recurrence.frequency === "one_time" ? null : current.recurrenceSeriesId ?? crypto.randomUUID()
      : undefined;
    const result = await prisma.task.updateMany({
      where: { id, workspaceId, version: input.version },
      data: { title: input.title, projectId: input.projectId, dueDate: input.dueDate === undefined ? undefined : asDatabaseDate(input.dueDate), ...recurrence, recurrenceSeriesId: seriesId, version: { increment: 1 } },
    });
    if (!result.count) throw new AppError("VERSION_CONFLICT", "Task changed since it was loaded", 409);
    return this.get(workspaceId, id);
  },

  async remove(workspaceId: number, id: number) {
    const result = await prisma.task.deleteMany({ where: { id, workspaceId } });
    if (!result.count) throw new AppError("TASK_NOT_FOUND", "Task not found", 404);
    return { id };
  },

  async setCompletion(userId: number, workspaceId: number, id: number, completed: boolean, version: number) {
    const timezone = await timezoneForUser(userId);
    const today = dateInTimeZone(new Date(), timezone);
    await prisma.$transaction(async (transaction) => {
      const task = await transaction.task.findFirst({ where: { id, workspaceId }, include: { subtasks: true, nextOccurrences: { select: { id: true } } } });
      if (!task) throw new AppError("TASK_NOT_FOUND", "Task not found", 404);
      if (task.version !== version) throw new AppError("VERSION_CONFLICT", "Task changed since it was loaded", 409);
      const dueDate = asDateString(task.dueDate);
      if (completed && dueDate && dueDate > today) throw new AppError("TASK_FUTURE_DATED", "A future task cannot be completed early", 409);
      if (completed && task.subtasks.some((subtask) => subtask.status !== TaskStatus.COMPLETED)) throw new AppError("TASK_SUBTASKS_INCOMPLETE", "Complete all subtasks before finishing this task", 409);
      await transaction.task.update({ where: { id }, data: { status: completed ? TaskStatus.COMPLETED : TaskStatus.OPEN, completedAt: completed ? new Date() : null, version: { increment: 1 } } });
      if (!completed || !dueDate || task.nextOccurrences.length) return;
      const rule = recurrenceFromTask(task);
      const nextDueDate = nextOccurrenceDate(dueDate, rule, today);
      if (!nextDueDate) return;
      await transaction.task.create({
        data: {
          workspaceId,
          projectId: task.projectId,
          title: task.title,
          dueDate: asDatabaseDate(nextDueDate),
          recurrenceFrequency: task.recurrenceFrequency,
          recurrenceInterval: task.recurrenceInterval,
          recurrenceUnit: task.recurrenceUnit,
          recurrenceSeriesId: task.recurrenceSeriesId,
          previousOccurrenceId: task.id,
          occurrenceNumber: task.occurrenceNumber + 1,
          subtasks: { create: task.subtasks.map((subtask) => ({ title: subtask.title, position: subtask.position })) },
        },
      });
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
    return this.get(workspaceId, id);
  },

  async addSubtask(workspaceId: number, taskId: number, title: string) {
    const task = await taskRepository.find(workspaceId, taskId);
    if (!task) throw new AppError("TASK_NOT_FOUND", "Task not found", 404);
    const subtask = await prisma.$transaction(async (transaction) => {
      const created = await transaction.subtask.create({ data: { taskId, title, position: task.subtasks.length } });
      if (task.status === TaskStatus.COMPLETED) await transaction.task.update({ where: { id: taskId }, data: { status: TaskStatus.OPEN, completedAt: null, version: { increment: 1 } } });
      return created;
    });
    return { ...subtask, completed: false };
  },

  async updateSubtask(workspaceId: number, taskId: number, subtaskId: number, title: string, version: number) {
    const result = await prisma.subtask.updateMany({ where: { id: subtaskId, taskId, version, task: { workspaceId } }, data: { title, version: { increment: 1 } } });
    if (!result.count) throw new AppError("SUBTASK_NOT_FOUND_OR_CHANGED", "Subtask not found or changed since it was loaded", 409);
    return prisma.subtask.findUnique({ where: { id: subtaskId } });
  },

  async removeSubtask(workspaceId: number, taskId: number, subtaskId: number) {
    const result = await prisma.subtask.deleteMany({ where: { id: subtaskId, taskId, task: { workspaceId } } });
    if (!result.count) throw new AppError("SUBTASK_NOT_FOUND", "Subtask not found", 404);
    return { id: subtaskId };
  },

  async setSubtaskCompletion(workspaceId: number, taskId: number, subtaskId: number, completed: boolean, version: number) {
    await prisma.$transaction(async (transaction) => {
      const result = await transaction.subtask.updateMany({
        where: { id: subtaskId, taskId, version, task: { workspaceId } },
        data: { status: completed ? TaskStatus.COMPLETED : TaskStatus.OPEN, completedAt: completed ? new Date() : null, version: { increment: 1 } },
      });
      if (!result.count) throw new AppError("SUBTASK_NOT_FOUND_OR_CHANGED", "Subtask not found or changed since it was loaded", 409);
      await transaction.task.update({ where: { id: taskId }, data: { status: TaskStatus.OPEN, completedAt: null, version: { increment: 1 } } });
    });
    return this.get(workspaceId, taskId);
  },

  async materializeOverdue(userId: number, workspaceId: number) {
    const today = dateInTimeZone(new Date(), await timezoneForUser(userId));
    const candidates = await prisma.task.findMany({
      where: { workspaceId, status: TaskStatus.OPEN, dueDate: { lt: asDatabaseDate(today)! }, recurrenceFrequency: { not: RecurrenceFrequency.ONE_TIME }, nextOccurrences: { none: {} } },
      include: { subtasks: true },
    });
    for (const task of candidates) {
      const dueDate = asDateString(task.dueDate);
      if (!dueDate) continue;
      const latest = latestOccurrenceDate(dueDate, recurrenceFromTask(task), today);
      if (!latest || latest <= dueDate) continue;
      try {
        await prisma.task.create({ data: {
          workspaceId, projectId: task.projectId, title: task.title, dueDate: asDatabaseDate(latest), recurrenceFrequency: task.recurrenceFrequency,
          recurrenceInterval: task.recurrenceInterval, recurrenceUnit: task.recurrenceUnit, recurrenceSeriesId: task.recurrenceSeriesId,
          previousOccurrenceId: task.id, occurrenceNumber: task.occurrenceNumber + 1,
          subtasks: { create: task.subtasks.map((subtask) => ({ title: subtask.title, position: subtask.position })) },
        } });
      } catch (error) {
        if (!(error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002")) throw error;
      }
    }
  },
};