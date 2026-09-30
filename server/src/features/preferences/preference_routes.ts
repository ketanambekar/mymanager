import { Router } from "express";
import { ThemePreference } from "@prisma/client";
import { z } from "zod";
import { prisma } from "../../database/prisma.js";
import { asyncHandler } from "../../shared/async_handler.js";
import { validateRequest } from "../../shared/validate_request.js";
import { authenticatedUser } from "../auth/auth_context.js";

const preferenceSchema = z.object({
  theme: z.enum(["dark", "light"]).optional(),
  timezone: z.string().trim().min(1).max(64).refine((value) => {
    try { new Intl.DateTimeFormat("en", { timeZone: value }); return true; } catch { return false; }
  }, "Invalid IANA timezone").optional(),
  version: z.number().int().positive(),
}).strict();

export const preferenceRouter = Router();
preferenceRouter.patch("/", validateRequest({ body: preferenceSchema }), asyncHandler(async (request, response) => {
  const auth = authenticatedUser(request);
  const body = request.validatedBody as { theme?: "dark" | "light"; timezone?: string; version: number };
  const result = await prisma.userPreference.updateMany({
    where: { userId: auth.sub, version: body.version },
    data: { theme: body.theme ? (body.theme === "dark" ? ThemePreference.DARK : ThemePreference.LIGHT) : undefined, timezone: body.timezone, version: { increment: 1 } },
  });
  if (!result.count) {
    response.status(409).json({ success: false, error: { code: "VERSION_CONFLICT", message: "Preferences changed since they were loaded", requestId: request.requestId } });
    return;
  }
  response.status(200).json({ success: true, data: await prisma.userPreference.findUnique({ where: { userId: auth.sub } }) });
}));