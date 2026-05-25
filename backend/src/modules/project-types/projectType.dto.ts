import { z } from "zod";
import { createProjectTypeSchema, updateProjectTypeSchema } from "./projectType.validation";

export type CreateProjectTypeDto = z.infer<typeof createProjectTypeSchema.shape.body>;
export type UpdateProjectTypeDto = z.infer<typeof updateProjectTypeSchema.shape.body>;
