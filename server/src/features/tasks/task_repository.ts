import { prisma } from "../../database/prisma.js";

export const taskInclude = {
  subtasks: { orderBy: [{ position: "asc" as const }, { id: "asc" as const }] },
  project: { select: { id: true, name: true, color: true } },
};

export const taskRepository = {
  find: (workspaceId: number, id: number) => prisma.task.findFirst({ where: { id, workspaceId }, include: taskInclude }),
  findForCompletion: (workspaceId: number, id: number) => prisma.task.findFirst({
    where: { id, workspaceId },
    include: { ...taskInclude, nextOccurrences: { select: { id: true } } },
  }),
};