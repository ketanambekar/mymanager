import { Router, type RequestHandler } from "express";
import rateLimit from "express-rate-limit";
import { validateRequest } from "../../shared/validate_request.js";
import { authenticatedUser, requireAuth } from "./auth_context.js";
import { authController } from "./auth_controller.js";
import { challengeParamsSchema, challengeSecretSchema, createChallengeSchema, decideChallengeSchema, deviceParamsSchema, googleLoginSchema, loginCodeSchema } from "./auth_schema.js";
import { frontendOrigins } from "../../config/env.js";
import { AppError } from "../../shared/app_error.js";

export const authRouter = Router();
const googleLoginLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 30, standardHeaders: true, legacyHeaders: false });
const refreshLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 60, standardHeaders: true, legacyHeaders: false });
const qrLimitHandler: RequestHandler = (request, response) => {
  response.status(429).json({ success: false, error: { code: "RATE_LIMITED", message: "Too many login attempts. Please try again later.", requestId: request.requestId } });
};
const createLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 10, standardHeaders: true, legacyHeaders: false, handler: qrLimitHandler });
const pollLimiter = rateLimit({ windowMs: 60 * 1000, limit: 30, standardHeaders: true, legacyHeaders: false, handler: qrLimitHandler });
const lookupLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, limit: 20, standardHeaders: true, legacyHeaders: false,
  keyGenerator: (request) => `user:${authenticatedUser(request).sub}`, handler: qrLimitHandler,
});

authRouter.use((request, _response, next) => {
  const origin = request.header("origin");
  if (request.method !== "GET" && origin && !frontendOrigins.includes(origin)) {
    next(new AppError("ORIGIN_NOT_ALLOWED", "Request origin is not allowed", 403));
    return;
  }
  next();
});

authRouter.post("/google", googleLoginLimiter, validateRequest({ body: googleLoginSchema }), authController.login);
authRouter.post("/refresh", refreshLimiter, authController.refresh);
authRouter.post("/logout", authController.logout);
authRouter.get("/session", requireAuth, authController.session);
authRouter.get("/devices", requireAuth, authController.devices);
authRouter.delete("/devices/:deviceId", requireAuth, validateRequest({ params: deviceParamsSchema }), authController.revokeDevice);
authRouter.post("/qr/challenges", createLimiter, validateRequest({ body: createChallengeSchema }), authController.createChallenge);
authRouter.post("/qr/lookup", requireAuth, lookupLimiter, validateRequest({ body: loginCodeSchema }), authController.lookupChallenge);
authRouter.post("/qr/challenges/:challengeId/decision", requireAuth, lookupLimiter, validateRequest({ params: challengeParamsSchema, body: decideChallengeSchema }), authController.decideChallenge);
authRouter.post("/qr/challenges/:challengeId/status", pollLimiter, validateRequest({ params: challengeParamsSchema, body: challengeSecretSchema }), authController.challengeStatus);
authRouter.post("/qr/challenges/:challengeId/consume", refreshLimiter, validateRequest({ params: challengeParamsSchema, body: challengeSecretSchema }), authController.consumeChallenge);
authRouter.post("/qr/challenges/:challengeId/cancel", pollLimiter, validateRequest({ params: challengeParamsSchema, body: challengeSecretSchema }), authController.cancelChallenge);