import { z } from "zod";

export const createProjectColorSchema = z.object({
  body: z.object({
    name: z.string().min(2).max(100),
    hexCode: z.string().regex(/^#([A-Fa-f0-9]{6})$/),
  }),
});

export const updateProjectColorSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
  body: z.object({
    name: z.string().min(2).max(100),
    hexCode: z.string().regex(/^#([A-Fa-f0-9]{6})$/),
  }),
});

export const projectColorIdSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
});
