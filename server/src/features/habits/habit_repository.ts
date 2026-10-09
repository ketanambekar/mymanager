import { Prisma } from "@prisma/client";
import { prisma } from "../../database/prisma.js";
import type { HabitListInput } from "./habit_schema.js";

export const habitSelect = {
  id: true, title: true, project: { select: { id: true, name: true, color: true } },
  recurrenceSeriesId: true, recurrenceFrequency: true, recurrenceInterval: true, recurrenceUnit: true,
  occurrenceNumber: true, dueDate: true, status: true, version: true,
} satisfies Prisma.TaskSelect;

export type HabitTask = Prisma.TaskGetPayload<{ select: typeof habitSelect }>;

export function isRecurringHabit(task: Pick<HabitTask, "recurrenceFrequency">) {
  return task.recurrenceFrequency !== "ONE_TIME";
}

export function habitIdFor(task: Pick<HabitTask, "id" | "recurrenceSeriesId">) {
  return task.recurrenceSeriesId ?? `task-${task.id}`;
}

export function habitWhere(workspaceId: number, habitId: string): Prisma.TaskWhereInput {
  return habitId.startsWith("task-")
    ? { workspaceId, id: Number(habitId.slice(5)), recurrenceSeriesId: null }
    : { workspaceId, recurrenceSeriesId: habitId };
}

export const habitRepository = {
  async list(db: Prisma.TransactionClient, workspaceId: number, input: HabitListInput) {
    const key = Prisma.sql`COALESCE(t.recurrenceSeriesId, CONCAT('task-', t.id))`;
    const ids = await db.$queryRaw<Array<{ id: number }>>(Prisma.sql`
      SELECT t.id FROM task t
      WHERE t.workspaceId = ${workspaceId}
        AND t.recurrenceFrequency <> 'ONE_TIME'
        AND (t.recurrenceSeriesId IS NULL OR NOT EXISTS (
          SELECT 1 FROM task newer
          WHERE newer.workspaceId = ${workspaceId} AND newer.recurrenceSeriesId = t.recurrenceSeriesId
            AND (newer.occurrenceNumber > t.occurrenceNumber
              OR (newer.occurrenceNumber = t.occurrenceNumber AND newer.id > t.id))
        ))
        ${input.cursor ? Prisma.sql`AND ${key} > ${input.cursor}` : Prisma.empty}
        ${input.projectId ? Prisma.sql`AND t.projectId = ${input.projectId}` : Prisma.empty}
        ${input.search ? Prisma.sql`AND LOCATE(${input.search}, t.title) > 0` : Prisma.empty}
      ORDER BY ${key} ASC
      LIMIT ${input.limit + 1}
    `);
    const tasks = await db.task.findMany({
      where: { workspaceId, id: { in: ids.map((row) => row.id) } }, select: habitSelect,
    });
    const byId = new Map(tasks.map((task) => [task.id, task]));
    return ids.map((row) => {
      const task = byId.get(row.id);
      if (!task) throw new Error("Habit list snapshot is inconsistent");
      return task;
    });
  },
  latest: (db: Prisma.TransactionClient, workspaceId: number, habitId: string) => db.task.findFirst({
    where: habitWhere(workspaceId, habitId),
    orderBy: [{ occurrenceNumber: "desc" }, { id: "desc" }], select: habitSelect,
  }),
  history: (db: Prisma.TransactionClient, workspaceId: number, habitId: string, start: Date, end: Date) => db.task.findMany({
    where: { ...habitWhere(workspaceId, habitId), dueDate: { gte: start, lt: end } },
    orderBy: [{ dueDate: "asc" }, { id: "asc" }],
    select: {
      id: true, title: true, dueDate: true, status: true, version: true,
      completedAt: true, closedAt: true, closeReason: true,
      recurrenceFrequency: true, recurrenceInterval: true, recurrenceUnit: true,
    },
  }),
  coverage: (db: Prisma.TransactionClient, workspaceId: number, habitId: string) => db.task.aggregate({
    where: { ...habitWhere(workspaceId, habitId), OR: [
      { recurrenceFrequency: "DAILY" },
      { recurrenceFrequency: "CUSTOM", recurrenceInterval: 1, recurrenceUnit: "DAY" },
    ] },
    _min: { dueDate: true },
  }),
  async recordedHistory(db: Prisma.TransactionClient, workspaceId: number, habitId: string) {
    const identity = habitId.startsWith("task-")
      ? Prisma.sql`id = ${Number(habitId.slice(5))} AND recurrenceSeriesId IS NULL`
      : Prisma.sql`recurrenceSeriesId = ${habitId}`;
    const months = await db.$queryRaw<Array<{ month: string; firstDate: Date; lastDate: Date }>>(Prisma.sql`
      SELECT DATE_FORMAT(dueDate, '%Y-%m') AS month,
        MIN(dueDate) AS firstDate, MAX(dueDate) AS lastDate
      FROM task
      WHERE workspaceId = ${workspaceId} AND ${identity} AND dueDate IS NOT NULL
      GROUP BY DATE_FORMAT(dueDate, '%Y-%m')
      ORDER BY month ASC
    `);
    return {
      firstRecordedDate: months[0]?.firstDate.toISOString().slice(0, 10) ?? null,
      lastRecordedDate: months.at(-1)?.lastDate.toISOString().slice(0, 10) ?? null,
      availableMonths: months.map((row) => row.month),
    };
  },
  undatedCount: (db: Prisma.TransactionClient, workspaceId: number, habitId: string) => db.task.count({
    where: { ...habitWhere(workspaceId, habitId), dueDate: null },
  }),
};

export const habitSnapshot = <T>(work: (db: Prisma.TransactionClient) => Promise<T>) =>
  prisma.$transaction(work, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
