import { prisma } from "../../lib/prisma";
import { CreateTaskDto, UpdateTaskDto } from "./task.dto";

const includeRelations = {
  project: true,
  priority: true,
  subtasks: {
    where: { isDeleted: false },
  },
};

export const taskRepository = {
  create: (userId: number, payload: CreateTaskDto) =>
    prisma.task.create({
      data: {
        ...payload,
        userId,
      },
      include: includeRelations,
    }),

  findAll: (userId: number) =>
    prisma.task.findMany({
      where: { userId, isDeleted: false },
      include: includeRelations,
      orderBy: { id: "desc" },
    }),

  findByProjectId: (userId: number, projectId: number) =>
    prisma.task.findMany({
      where: { userId, projectId, isDeleted: false },
      include: includeRelations,
      orderBy: { id: "desc" },
    }),

  findById: (userId: number, id: number) =>
    prisma.task.findFirst({
      where: { id, userId, isDeleted: false },
      include: includeRelations,
    }),

  update: async (userId: number, id: number, payload: UpdateTaskDto) => {
    await prisma.task.updateMany({
      where: { id, userId, isDeleted: false },
      data: payload,
    });

    return prisma.task.findFirstOrThrow({
      where: { id, userId, isDeleted: false },
      include: includeRelations,
    });
  },

  softDelete: (userId: number, id: number) =>
    prisma.task.updateMany({
      where: { id, userId, isDeleted: false },
      data: { isDeleted: true, deletedAt: new Date() },
    }),
};
