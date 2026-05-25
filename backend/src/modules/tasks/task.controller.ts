import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { requireAuthUserId } from "../../utils/authUser";
import { taskService } from "./task.service";

export const taskController = {
  create: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await taskService.create(userId, req.validatedBody as never);
    res.status(201).json({ success: true, data });
  }),

  getAll: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await taskService.getAll(userId);
    res.status(200).json({ success: true, data });
  }),

  getByProject: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { projectId } = req.validatedParams as { projectId: number };
    const data = await taskService.getByProject(userId, projectId);
    res.status(200).json({ success: true, data });
  }),

  getById: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await taskService.getById(userId, id);
    res.status(200).json({ success: true, data });
  }),

  update: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await taskService.update(userId, id, req.validatedBody as never);
    res.status(200).json({ success: true, data });
  }),

  remove: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    await taskService.remove(userId, id);
    res.status(200).json({ success: true, message: "Task deleted" });
  }),
};
