import { prisma } from "../../database/prisma.js";

export const projectRepository = {
  list: (workspaceId: number) => prisma.project.findMany({
    where: { workspaceId },
    include: { tasks: { include: { subtasks: true } } },
    orderBy: [{ createdAt: "asc" }, { id: "asc" }],
  }),
  find: (workspaceId: number, id: number) => prisma.project.findFirst({ where: { id, workspaceId } }),
};