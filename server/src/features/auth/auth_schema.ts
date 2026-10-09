import { z } from "zod";

export const googleLoginSchema = z.object({ credential: z.string().min(20).max(8192) }).strict();

export const createChallengeSchema = z.object({ deviceName: z.string().trim().min(1).max(120).optional() }).strict();
export const loginCodeSchema = z.object({ code: z.string().regex(/^\d{10}$/) }).strict();
export const challengeSecretSchema = z.object({ pollToken: z.string().regex(/^[A-Za-z0-9_-]{64}$/) }).strict();
export const challengeParamsSchema = z.object({ challengeId: z.uuid() });
export const decideChallengeSchema = z.object({
  code: z.string().regex(/^\d{10}$/),
  decision: z.enum(["approve", "deny"]),
}).strict();
export const deviceParamsSchema = z.object({ deviceId: z.string().min(1).max(64) });