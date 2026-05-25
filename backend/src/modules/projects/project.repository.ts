import { prisma } from "../../lib/prisma";
import { CreateProjectDto, UpdateProjectDto } from "./project.dto";

const includeRelations = {
  type: true,
  color: true,
  priority: true,
};

export const projectRepository = {
  create: (userId: number, payload: CreateProjectDto) =>
    prisma.project.create({
      data: {
        ...payload,
        userId,
      },
      include: includeRelations,
    }),

  findAll: (userId: number) =>
    prisma.project.findMany({
      where: { userId, isDeleted: false },
      include: includeRelations,
      orderBy: { id: "desc" },
    }),

  findById: (userId: number, id: number) =>
    prisma.project.findFirst({
      where: { id, userId, isDeleted: false },
      include: includeRelations,
    }),

  update: async (userId: number, id: number, payload: UpdateProjectDto) => {
    await prisma.project.updateMany({
      where: { id, userId, isDeleted: false },
      data: payload,
    });

    return prisma.project.findFirstOrThrow({
      where: { id, userId, isDeleted: false },
      include: includeRelations,
    });
  },

  softDelete: (userId: number, id: number) =>
    prisma.project.updateMany({
      where: { id, userId, isDeleted: false },
      data: { isDeleted: true, deletedAt: new Date() },
    }),
};
