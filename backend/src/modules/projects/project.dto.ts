import { z } from "zod";
import { createProjectSchema, updateProjectSchema } from "./project.validation";

export type CreateProjectDto = z.infer<typeof createProjectSchema.shape.body>;
export type UpdateProjectDto = z.infer<typeof updateProjectSchema.shape.body>;
