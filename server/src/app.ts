import crypto from "node:crypto";
import cookieParser from "cookie-parser";
import cors from "cors";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import { frontendOrigins } from "./config/env.js";
import { attachAuthContext } from "./features/auth/auth_context.js";
import { authRouter } from "./features/auth/auth_routes.js";
import { requireAuth } from "./features/auth/auth_context.js";
import { dashboardRouter } from "./features/dashboard/dashboard_routes.js";
import { preferenceRouter } from "./features/preferences/preference_routes.js";
import { projectRouter } from "./features/projects/project_routes.js";
import { taskRouter } from "./features/tasks/task_routes.js";
import { errorMiddleware } from "./shared/error_middleware.js";

export const app = express();

app.disable("x-powered-by");
app.use((request, response, next) => {
  request.requestId = request.header("x-request-id")?.slice(0, 100) || crypto.randomUUID();
  response.setHeader("x-request-id", request.requestId);
  next();
});
app.use(helmet());
app.use(cors({ origin: frontendOrigins, credentials: true }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 300, standardHeaders: true, legacyHeaders: false }));
app.use(express.json({ limit: "64kb" }));
app.use(cookieParser());
app.use(attachAuthContext);

app.get("/health", (_request, response) => {
  response.status(200).json({ success: true, data: { status: "ok" } });
});

app.use("/api/v1/auth", authRouter);
app.use("/api/v1", requireAuth);
app.use("/api/v1/dashboard", dashboardRouter);
app.use("/api/v1/projects", projectRouter);
app.use("/api/v1/tasks", taskRouter);
app.use("/api/v1/me/preferences", preferenceRouter);
app.use(errorMiddleware);