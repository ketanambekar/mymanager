import { AppError } from "../../utils/appError";
import { prisma } from "../../lib/prisma";
import { CreateSubTaskDto, UpdateSubTaskDto } from "./subTask.dto";
import { subTaskRepository } from "./subTask.repository";

async function validateTask(userId: number, taskId?: number): Promise<void> {
  if (!taskId) {
    return;
  }

  const task = await prisma.task.findFirst({ where: { id: taskId, userId, isDeleted: false } });
  if (!task) {
    throw new AppError("Invalid taskId", 400);
  }
}

export const subTaskService = {
  async create(userId: number, payload: CreateSubTaskDto) {
    await validateTask(userId, payload.taskId);
    return subTaskRepository.create(userId, payload);
  },

  getAll: (userId: number) => subTaskRepository.findAll(userId),

  async getById(userId: number, id: number) {
    const item = await subTaskRepository.findById(userId, id);
    if (!item) {
      throw new AppError("Subtask not found", 404);
    }
    return item;
  },

  async update(userId: number, id: number, payload: UpdateSubTaskDto) {
    await this.getById(userId, id);
    await validateTask(userId, payload.taskId);
    return subTaskRepository.update(userId, id, payload);
  },

  async remove(userId: number, id: number) {
    await this.getById(userId, id);
    return subTaskRepository.softDelete(userId, id);
  },
};
