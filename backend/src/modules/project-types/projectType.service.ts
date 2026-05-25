import { AppError } from "../../utils/appError";
import { CreateProjectTypeDto, UpdateProjectTypeDto } from "./projectType.dto";
import { projectTypeRepository } from "./projectType.repository";

export const projectTypeService = {
  create: (userId: number, payload: CreateProjectTypeDto) => projectTypeRepository.create(userId, payload),

  getAll: (userId: number) => projectTypeRepository.findAll(userId),

  async getById(userId: number, id: number) {
    const item = await projectTypeRepository.findById(userId, id);
    if (!item) {
      throw new AppError("Project type not found", 404);
    }
    return item;
  },

  async update(userId: number, id: number, payload: UpdateProjectTypeDto) {
    await this.getById(userId, id);
    return projectTypeRepository.update(userId, id, payload);
  },

  async remove(userId: number, id: number) {
    await this.getById(userId, id);
    return projectTypeRepository.softDelete(userId, id);
  },
};
