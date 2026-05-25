import { AppError } from "../../utils/appError";
import { MasterScope } from "@prisma/client";
import { prisma } from "../../lib/prisma";
import { CreateProjectDto, UpdateProjectDto } from "./project.dto";
import { projectRepository } from "./project.repository";

async function validateReferences(userId: number, typeId?: number, colorId?: number, priorityId?: number): Promise<void> {
  if (typeId) {
    const type = await prisma.projectType.findFirst({
      where: {
        id: typeId,
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
    });
    if (!type) {
      throw new AppError("Invalid typeId", 400);
    }
  }

  if (colorId) {
    const color = await prisma.projectColor.findFirst({
      where: {
        id: colorId,
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
    });
    if (!color) {
      throw new AppError("Invalid colorId", 400);
    }
  }

  if (priorityId) {
    const priority = await prisma.priority.findFirst({
      where: {
        id: priorityId,
        isDeleted: false,
        OR: [{ scope: MasterScope.SYSTEM }, { ownerUserId: userId }],
      },
    });
    if (!priority) {
      throw new AppError("Invalid priorityId", 400);
    }
  }
}

export const projectService = {
  async create(userId: number, payload: CreateProjectDto) {
    await validateReferences(userId, payload.typeId, payload.colorId, payload.priorityId);
    return projectRepository.create(userId, payload);
  },

  getAll: (userId: number) => projectRepository.findAll(userId),

  async getById(userId: number, id: number) {
    const item = await projectRepository.findById(userId, id);
    if (!item) {
      throw new AppError("Project not found", 404);
    }
    return item;
  },

  async update(userId: number, id: number, payload: UpdateProjectDto) {
    await this.getById(userId, id);
    await validateReferences(userId, payload.typeId, payload.colorId, payload.priorityId);
    return projectRepository.update(userId, id, payload);
  },

  async remove(userId: number, id: number) {
    await this.getById(userId, id);
    return projectRepository.softDelete(userId, id);
  },
};
