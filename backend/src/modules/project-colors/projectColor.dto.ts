import { z } from "zod";
import { createProjectColorSchema, updateProjectColorSchema } from "./projectColor.validation";

export type CreateProjectColorDto = z.infer<typeof createProjectColorSchema.shape.body>;
export type UpdateProjectColorDto = z.infer<typeof updateProjectColorSchema.shape.body>;
