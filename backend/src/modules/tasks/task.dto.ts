import { z } from "zod";
import { createTaskSchema, updateTaskSchema } from "./task.validation";

export type CreateTaskDto = z.infer<typeof createTaskSchema.shape.body>;
export type UpdateTaskDto = z.infer<typeof updateTaskSchema.shape.body>;
