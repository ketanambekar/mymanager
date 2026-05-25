import { TaskStatus } from "@prisma/client";
import { z } from "zod";

const baseBody = z.object({
  taskId: z.coerce.number().int().positive(),
  name: z.string().min(2).max(150),
  description: z.string().max(1000).optional().nullable(),
  status: z.nativeEnum(TaskStatus).default(TaskStatus.PENDING),
});

export const createSubTaskSchema = z.object({
  body: baseBody,
});

export const updateSubTaskSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
  body: baseBody.partial(),
});

export const subTaskIdSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
});
