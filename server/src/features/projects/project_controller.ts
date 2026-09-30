import { asyncHandler } from "../../shared/async_handler.js";
import { authenticatedUser } from "../auth/auth_context.js";
import { projectService } from "./project_service.js";

const idFrom = (value: unknown) => (value as { projectId: number }).projectId;

export const projectController = {
  list: asyncHandler(async (request, response) => response.status(200).json({ success: true, data: await projectService.list(authenticatedUser(request).workspaceId) })),
  get: asyncHandler(async (request, response) => response.status(200).json({ success: true, data: await projectService.get(authenticatedUser(request).workspaceId, idFrom(request.validatedParams)) })),
  create: asyncHandler(async (request, response) => response.status(201).json({ success: true, data: await projectService.create(authenticatedUser(request).workspaceId, request.validatedBody as never) })),
  update: asyncHandler(async (request, response) => response.status(200).json({ success: true, data: await projectService.update(authenticatedUser(request).workspaceId, idFrom(request.validatedParams), request.validatedBody as never) })),
  remove: asyncHandler(async (request, response) => response.status(200).json({ success: true, data: await projectService.remove(authenticatedUser(request).workspaceId, idFrom(request.validatedParams)) })),
};