import { z } from "zod";

const optionalIconUrlSchema = z
  .string()
  .trim()
  .url()
  .or(z.literal(""))
  .or(z.null())
  .optional()
  .transform((value) => (value ? value : undefined));

export const createProjectTypeSchema = z.object({
  body: z.object({
    name: z.string().min(2).max(100),
    iconUrl: optionalIconUrlSchema,
  }),
});

export const updateProjectTypeSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
  body: z.object({
    name: z.string().min(2).max(100),
    iconUrl: optionalIconUrlSchema,
  }),
});

export const projectTypeIdSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
});
