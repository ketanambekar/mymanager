import { AppError } from "../../utils/appError";
import { MasterScope } from "@prisma/client";
import { prisma } from "../../lib/prisma";
import { CreateTaskDto, UpdateTaskDto } from "./task.dto";
import { taskRepository } from "./task.repository";

async function validateReferences(userId: number, projectId?: number, priorityId?: number): Promise<void> {
  if (projectId) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId, isDeleted: false } });
    if (!project) {
      throw new AppError("Invalid projectId", 400);
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

export const taskService = {
  async create(userId: number, payload: CreateTaskDto) {
    await validateReferences(userId, payload.projectId, payload.priorityId);
    return taskRepository.create(userId, payload);
  },

  getAll: (userId: number) => taskRepository.findAll(userId),

  async getByProject(userId: number, projectId: number) {
    await validateReferences(userId, projectId, undefined);
    return taskRepository.findByProjectId(userId, projectId);
  },

  async getById(userId: number, id: number) {
    const item = await taskRepository.findById(userId, id);
    if (!item) {
      throw new AppError("Task not found", 404);
    }
    return item;
  },

  async update(userId: number, id: number, payload: UpdateTaskDto) {
    await this.getById(userId, id);
    await validateReferences(userId, payload.projectId, payload.priorityId);
    return taskRepository.update(userId, id, payload);
  },

  async remove(userId: number, id: number) {
    await this.getById(userId, id);
    return taskRepository.softDelete(userId, id);
  },
};
