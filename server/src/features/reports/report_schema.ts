import { z } from "zod";

export const reportQuerySchema = z.object({
  year: z.coerce.number().int().min(1900).max(2199).optional(),
}).strict();
