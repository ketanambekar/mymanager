import { TaskFrequency, TaskStatus } from "@prisma/client";
import { z } from "zod";

const baseBody = z.object({
  projectId: z.coerce.number().int().positive(),
  name: z.string().min(2).max(150),
  description: z.string().max(1000).optional().nullable(),
  priorityId: z.coerce.number().int().positive(),
  frequency: z.nativeEnum(TaskFrequency).default(TaskFrequency.ONCE),
  alertEnabled: z.boolean().default(false),
  alertBeforeMinutes: z.coerce.number().int().nonnegative().optional().nullable(),
  startDateTime: z.coerce.date().optional().nullable(),
  endDateTime: z.coerce.date().optional().nullable(),
  durationMinutes: z.coerce.number().int().nonnegative().optional().nullable(),
  status: z.nativeEnum(TaskStatus).default(TaskStatus.PENDING),
});

export const createTaskSchema = z.object({
  body: baseBody,
});

export const updateTaskSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
  body: baseBody.partial(),
});

export const taskIdSchema = z.object({
  params: z.object({
    id: z.coerce.number().int().positive(),
  }),
});

export const taskProjectIdSchema = z.object({
  params: z.object({
    projectId: z.coerce.number().int().positive(),
  }),
});
