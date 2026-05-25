import { z } from "zod";
import { createSubTaskSchema, updateSubTaskSchema } from "./subTask.validation";

export type CreateSubTaskDto = z.infer<typeof createSubTaskSchema.shape.body>;
export type UpdateSubTaskDto = z.infer<typeof updateSubTaskSchema.shape.body>;
