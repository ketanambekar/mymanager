import { z } from "zod";

export const loginWithGoogleSchema = z.object({
  body: z.object({
    credential: z.string().min(20, "Google credential is required"),
  }),
});
