import { AppError } from "../../utils/appError";
import { CreateProjectColorDto, UpdateProjectColorDto } from "./projectColor.dto";
import { projectColorRepository } from "./projectColor.repository";

export const projectColorService = {
  create: (userId: number, payload: CreateProjectColorDto) => projectColorRepository.create(userId, payload),

  getAll: (userId: number) => projectColorRepository.findAll(userId),

  async getById(userId: number, id: number) {
    const item = await projectColorRepository.findById(userId, id);
    if (!item) {
      throw new AppError("Project color not found", 404);
    }
    return item;
  },

  async update(userId: number, id: number, payload: UpdateProjectColorDto) {
    await this.getById(userId, id);
    return projectColorRepository.update(userId, id, payload);
  },

  async remove(userId: number, id: number) {
    await this.getById(userId, id);
    return projectColorRepository.softDelete(userId, id);
  },
};
