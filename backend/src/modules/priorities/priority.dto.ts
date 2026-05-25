import { z } from "zod";
import { createPrioritySchema, updatePrioritySchema } from "./priority.validation";

export type CreatePriorityDto = z.infer<typeof createPrioritySchema.shape.body>;
export type UpdatePriorityDto = z.infer<typeof updatePrioritySchema.shape.body>;
