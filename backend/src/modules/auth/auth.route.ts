import { Router } from "express";
import { requireAuth } from "../../middlewares/authContext";
import { validateRequest } from "../../middlewares/validateRequest";
import { authController } from "./auth.controller";
import { loginWithGoogleSchema } from "./auth.validation";

export const authRouter = Router();

authRouter.post("/google", validateRequest({ body: loginWithGoogleSchema.shape.body }), authController.loginWithGoogle);
authRouter.post("/refresh", authController.refreshToken);
authRouter.post("/logout", authController.logout);
authRouter.get("/me", requireAuth, authController.getCurrentUser);
