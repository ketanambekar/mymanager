import { Router } from "express";
import { asyncHandler } from "../../shared/async_handler.js";
import { validateRequest } from "../../shared/validate_request.js";
import { authenticatedUser } from "../auth/auth_context.js";
import { reportQuerySchema } from "./report_schema.js";
import { reportService } from "./report_service.js";

export const reportRouter = Router();
reportRouter.get("/", validateRequest({ query: reportQuerySchema }), asyncHandler(async (request, response) => {
  const auth = authenticatedUser(request);
  const { year } = request.validatedQuery as { year?: number };
  response.setHeader("Cache-Control", "no-store");
  response.json({ success: true, data: await reportService.get(auth.sub, auth.workspaceId, year) });
}));
