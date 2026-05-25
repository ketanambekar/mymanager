import { ProjectStatus } from "@prisma/client";
import { z } from "zod";

const baseBody = z.object({
  name: z.string().min(2).max(150),
  description: z.string().max(1000).optional().nullable(),
  typeId: z.coerce.number().int().positive(),
  colorId: z.coerce.number().int().positive(),
  priorityId: z.coerce.number().int().positive(),
  status: z.nativeEnum(ProjectStatus).default(ProjectStatus.ACTIVE),
  dpImage: z.string().url().optional().nullable(),
});

export const createProjectSchema = z.object({
  body: baseBody,
});

export const updateProjectSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
  body: baseBody.partial(),
});

export const projectIdSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
});
