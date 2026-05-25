import { AppError } from "../../utils/appError";
import { CreatePriorityDto, UpdatePriorityDto } from "./priority.dto";
import { priorityRepository } from "./priority.repository";

export const priorityService = {
  create: (userId: number, payload: CreatePriorityDto) => priorityRepository.create(userId, payload),

  getAll: (userId: number) => priorityRepository.findAll(userId),

  async getById(userId: number, id: number) {
    const item = await priorityRepository.findById(userId, id);
    if (!item) {
      throw new AppError("Priority not found", 404);
    }
    return item;
  },

  async update(userId: number, id: number, payload: UpdatePriorityDto) {
    await this.getById(userId, id);
    return priorityRepository.update(userId, id, payload);
  },

  async remove(userId: number, id: number) {
    await this.getById(userId, id);
    return priorityRepository.softDelete(userId, id);
  },
};
