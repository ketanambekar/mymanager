import { Prisma } from "@prisma/client";
import { prisma } from "../../database/prisma.js";

export const reportTaskSelect = {
  id: true, projectId: true, title: true, dueDate: true, status: true, completedAt: true,
  closedAt: true, closeReason: true, recurrenceSeriesId: true, recurrenceFrequency: true,
  recurrenceInterval: true, recurrenceUnit: true, occurrenceNumber: true,
} satisfies Prisma.TaskSelect;
export type ReportTask = Prisma.TaskGetPayload<{ select: typeof reportTaskSelect }>;

export const reportRepository = {
  preference: (db: Prisma.TransactionClient, userId: number) =>
    db.userPreference.findUnique({ where: { userId }, select: { timezone: true } }),
  tasks: (db: Prisma.TransactionClient, workspaceId: number, year: number) => {
    const start = new Date(`${year}-01-01T00:00:00Z`);
    const end = new Date(`${year + 1}-01-01T00:00:00Z`);
    const activityStart = new Date(start.getTime() - 86400000);
    const activityEnd = new Date(end.getTime() + 86400000);
    return db.task.findMany({
      where: { workspaceId, OR: [
        { dueDate: { gte: start, lt: end } },
        { completedAt: { gte: activityStart, lt: activityEnd } },
        { closedAt: { gte: activityStart, lt: activityEnd } },
      ] }, select: reportTaskSelect, orderBy: { id: "asc" },
    });
  },
  projects: (db: Prisma.TransactionClient, workspaceId: number) =>
    db.project.findMany({ where: { workspaceId }, select: { id: true, name: true, color: true, parentProjectId: true }, orderBy: { id: "asc" } }),
  inventory: (db: Prisma.TransactionClient, workspaceId: number) =>
    db.task.groupBy({ by: ["projectId", "status"], where: { workspaceId }, _count: { _all: true } }),
  overdue: (db: Prisma.TransactionClient, workspaceId: number, today: string) =>
    db.task.count({ where: { workspaceId, status: "OPEN", dueDate: { lt: new Date(`${today}T00:00:00Z`) } } }),
  undated: (db: Prisma.TransactionClient, workspaceId: number) =>
    db.task.count({ where: { workspaceId, dueDate: null } }),
};

export const reportSnapshot = <T>(work: (db: Prisma.TransactionClient) => Promise<T>) =>
  prisma.$transaction(work, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
