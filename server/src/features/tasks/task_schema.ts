import { z } from "zod";

const date = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const recurrence = z.object({
  frequency: z.enum(["one_time", "daily", "weekly", "monthly", "yearly", "custom"]),
  interval: z.number().int().min(1).max(365).optional(),
  unit: z.enum(["day", "week", "month", "year"]).optional(),
}).strict().superRefine((value, context) => {
  if (value.frequency === "custom" && (!value.interval || !value.unit)) context.addIssue({ code: "custom", message: "Custom recurrence requires interval and unit" });
});

const fields = z.object({
  title: z.string().trim().min(1).max(120),
  projectId: z.number().int().positive().nullable().optional(),
  dueDate: date.nullable().optional(),
  recurrence: recurrence.optional(),
}).strict();

export const createTaskSchema = fields;
export const updateTaskSchema = fields.partial().extend({ version: z.number().int().positive() }).strict();
export const taskIdSchema = z.object({ taskId: z.coerce.number().int().positive() });
export const subtaskIdSchema = taskIdSchema.extend({ subtaskId: z.coerce.number().int().positive() });
export const versionSchema = z.object({ version: z.number().int().positive() }).strict();
export const skipTaskSchema = versionSchema.extend({ reason: z.string().trim().min(1).max(200) }).strict();
export const missTaskSchema = skipTaskSchema;
export const subtaskCreateSchema = z.object({ title: z.string().trim().min(1).max(120) }).strict();
export const subtaskUpdateSchema = subtaskCreateSchema.extend({ version: z.number().int().positive() }).strict();
export const taskListSchema = z.object({
  status: z.enum(["all", "open", "completed", "skipped", "missed"]).default("all"),
  projectId: z.coerce.number().int().positive().optional(),
  search: z.string().trim().max(120).optional(),
  dateScope: z.enum(["recent", "upcoming", "all"]).default("all"),
  cursor: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});