import { MasterScope } from "@prisma/client";
import { prisma } from "../../lib/prisma";
import { CreateProjectTypeDto, UpdateProjectTypeDto } from "./projectType.dto";

export const projectTypeRepository = {
  create: (userId: number, payload: CreateProjectTypeDto) =>
    prisma.projectType.create({
      data: {
        ...payload,
        ownerUserId: userId,
        scope: MasterScope.USER,
      },
    }),

  findAll: (userId: number) =>
    prisma.projectType.findMany({
      where: {
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
      orderBy: { id: "desc" },
    }),

  findById: (userId: number, id: number) =>
    prisma.projectType.findFirst({
      where: {
        id,
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
    }),

  update: async (userId: number, id: number, payload: UpdateProjectTypeDto) => {
    await prisma.projectType.updateMany({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
      data: payload,
    });

    return prisma.projectType.findFirstOrThrow({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
    });
  },

  softDelete: (userId: number, id: number) =>
    prisma.projectType.updateMany({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
      data: { isDeleted: true, deletedAt: new Date() },
    }),
};
