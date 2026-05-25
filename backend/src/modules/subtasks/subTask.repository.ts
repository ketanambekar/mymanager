import { prisma } from "../../lib/prisma";
import { CreateSubTaskDto, UpdateSubTaskDto } from "./subTask.dto";

export const subTaskRepository = {
  create: (userId: number, payload: CreateSubTaskDto) =>
    prisma.subTask.create({
      data: {
        ...payload,
        userId,
      },
    }),

  findAll: (userId: number) =>
    prisma.subTask.findMany({
      where: { userId, isDeleted: false },
      orderBy: { id: "desc" },
    }),

  findById: (userId: number, id: number) =>
    prisma.subTask.findFirst({
      where: { id, userId, isDeleted: false },
    }),

  update: async (userId: number, id: number, payload: UpdateSubTaskDto) => {
    await prisma.subTask.updateMany({
      where: { id, userId, isDeleted: false },
      data: payload,
    });

    return prisma.subTask.findFirstOrThrow({
      where: { id, userId, isDeleted: false },
    });
  },

  softDelete: (userId: number, id: number) =>
    prisma.subTask.updateMany({
      where: { id, userId, isDeleted: false },
      data: { isDeleted: true, deletedAt: new Date() },
    }),
};
