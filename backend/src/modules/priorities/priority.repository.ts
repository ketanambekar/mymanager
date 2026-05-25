import { MasterScope } from "@prisma/client";
import { prisma } from "../../lib/prisma";
import { CreatePriorityDto, UpdatePriorityDto } from "./priority.dto";

export const priorityRepository = {
  create: (userId: number, payload: CreatePriorityDto) =>
    prisma.priority.create({
      data: {
        ...payload,
        ownerUserId: userId,
        scope: MasterScope.USER,
      },
    }),

  findAll: (userId: number) =>
    prisma.priority.findMany({
      where: {
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
      orderBy: { id: "desc" },
    }),

  findById: (userId: number, id: number) =>
    prisma.priority.findFirst({
      where: {
        id,
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
    }),

  update: async (userId: number, id: number, payload: UpdatePriorityDto) => {
    await prisma.priority.updateMany({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
      data: payload,
    });

    return prisma.priority.findFirstOrThrow({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
    });
  },

  softDelete: (userId: number, id: number) =>
    prisma.priority.updateMany({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
      data: { isDeleted: true, deletedAt: new Date() },
    }),
};
