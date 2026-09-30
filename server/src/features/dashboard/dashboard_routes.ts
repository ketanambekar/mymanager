import { Router } from "express";
import { asyncHandler } from "../../shared/async_handler.js";
import { authenticatedUser } from "../auth/auth_context.js";
import { dashboardService } from "./dashboard_service.js";

export const dashboardRouter = Router();
dashboardRouter.get("/", asyncHandler(async (request, response) => {
  const auth = authenticatedUser(request);
  response.status(200).json({ success: true, data: await dashboardService.get(auth.sub, auth.workspaceId) });
}));