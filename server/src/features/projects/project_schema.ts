import { z } from "zod";

const projectFields = z.object({
  name: z.string().trim().min(1).max(60),
  parentProjectId: z.number().int().positive().nullable().optional(),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).transform((value) => value.toUpperCase()),
}).strict();

export const createProjectSchema = projectFields;
export const updateProjectSchema = projectFields.partial().extend({ version: z.number().int().positive() }).strict();
export const projectIdSchema = z.object({ projectId: z.coerce.number().int().positive() });