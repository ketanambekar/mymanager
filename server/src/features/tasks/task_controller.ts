import { asyncHandler } from "../../shared/async_handler.js";
import { authenticatedUser } from "../auth/auth_context.js";
import { taskService } from "./task_service.js";

const ids = (value: unknown) => value as { taskId: number; subtaskId: number };

export const taskController = {
  list: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); response.status(200).json({ success: true, data: await taskService.list(auth.sub, auth.workspaceId, request.validatedQuery as never) }); }),
  get: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); response.status(200).json({ success: true, data: await taskService.get(auth.workspaceId, ids(request.validatedParams).taskId) }); }),
  create: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); response.status(201).json({ success: true, data: await taskService.create(auth.sub, auth.workspaceId, request.validatedBody as never) }); }),
  update: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); response.status(200).json({ success: true, data: await taskService.update(auth.workspaceId, ids(request.validatedParams).taskId, request.validatedBody as never) }); }),
  remove: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); response.status(200).json({ success: true, data: await taskService.remove(auth.workspaceId, ids(request.validatedParams).taskId) }); }),
  complete: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); response.status(200).json({ success: true, data: await taskService.setCompletion(auth.sub, auth.workspaceId, ids(request.validatedParams).taskId, true, (request.validatedBody as { version: number }).version) }); }),
  reopen: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); response.status(200).json({ success: true, data: await taskService.setCompletion(auth.sub, auth.workspaceId, ids(request.validatedParams).taskId, false, (request.validatedBody as { version: number }).version) }); }),
  addSubtask: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); response.status(201).json({ success: true, data: await taskService.addSubtask(auth.workspaceId, ids(request.validatedParams).taskId, (request.validatedBody as { title: string }).title) }); }),
  updateSubtask: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); const body = request.validatedBody as { title: string; version: number }; const value = ids(request.validatedParams); response.status(200).json({ success: true, data: await taskService.updateSubtask(auth.workspaceId, value.taskId, value.subtaskId, body.title, body.version) }); }),
  removeSubtask: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); const value = ids(request.validatedParams); response.status(200).json({ success: true, data: await taskService.removeSubtask(auth.workspaceId, value.taskId, value.subtaskId) }); }),
  completeSubtask: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); const value = ids(request.validatedParams); response.status(200).json({ success: true, data: await taskService.setSubtaskCompletion(auth.workspaceId, value.taskId, value.subtaskId, true, (request.validatedBody as { version: number }).version) }); }),
  reopenSubtask: asyncHandler(async (request, response) => { const auth = authenticatedUser(request); const value = ids(request.validatedParams); response.status(200).json({ success: true, data: await taskService.setSubtaskCompletion(auth.workspaceId, value.taskId, value.subtaskId, false, (request.validatedBody as { version: number }).version) }); }),
};