import { Router } from "express";
import rateLimit from "express-rate-limit";
import { validateRequest } from "../../shared/validate_request.js";
import { requireAuth } from "./auth_context.js";
import { authController } from "./auth_controller.js";
import { googleLoginSchema } from "./auth_schema.js";

export const authRouter = Router();
const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 30, standardHeaders: true, legacyHeaders: false });

authRouter.post("/google", authLimiter, validateRequest({ body: googleLoginSchema }), authController.login);
authRouter.post("/refresh", authLimiter, authController.refresh);
authRouter.post("/logout", authController.logout);
authRouter.get("/session", requireAuth, authController.session);