import { MasterScope } from "@prisma/client";
import { prisma } from "../../lib/prisma";
import { CreateProjectColorDto, UpdateProjectColorDto } from "./projectColor.dto";

export const projectColorRepository = {
  create: (userId: number, payload: CreateProjectColorDto) =>
    prisma.projectColor.create({
      data: {
        ...payload,
        ownerUserId: userId,
        scope: MasterScope.USER,
      },
    }),

  findAll: (userId: number) =>
    prisma.projectColor.findMany({
      where: {
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
      orderBy: { id: "desc" },
    }),

  findById: (userId: number, id: number) =>
    prisma.projectColor.findFirst({
      where: {
        id,
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
    }),

  update: async (userId: number, id: number, payload: UpdateProjectColorDto) => {
    await prisma.projectColor.updateMany({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
      data: payload,
    });

    return prisma.projectColor.findFirstOrThrow({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
    });
  },

  softDelete: (userId: number, id: number) =>
    prisma.projectColor.updateMany({
      where: { id, ownerUserId: userId, scope: MasterScope.USER, isDeleted: false },
      data: { isDeleted: true, deletedAt: new Date() },
    }),
};
