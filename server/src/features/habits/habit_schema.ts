import { z } from "zod";

const habitId = z.union([
  z.uuid(),
  z.string().regex(/^task-[1-9]\d{0,9}$/).refine((value) => Number(value.slice(5)) <= 2147483647, "Invalid task identifier"),
]);
export const habitParamsSchema = z.object({ habitId });
export const habitListSchema = z.object({
  cursor: habitId.optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  search: z.string().trim().max(120).optional(),
  projectId: z.coerce.number().int().positive().max(2147483647).optional(),
}).strict();
export const habitCalendarSchema = z.object({
  month: z.string().regex(/^(?:19|20|21)\d{2}-(?:0[1-9]|1[0-2])$/).optional(),
}).strict();
export const habitHistorySchema = z.object({
  year: z.coerce.number().int().min(1900).max(2199).optional(),
}).strict();

export type HabitListInput = z.infer<typeof habitListSchema>;
