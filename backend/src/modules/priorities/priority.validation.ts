import { z } from "zod";

export const createPrioritySchema = z.object({
  body: z.object({
    code: z.string().min(2).max(10),
    title: z.string().min(2).max(100),
  }),
});

export const updatePrioritySchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
  body: z.object({
    code: z.string().min(2).max(10),
    title: z.string().min(2).max(100),
  }),
});

export const priorityIdSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
});
