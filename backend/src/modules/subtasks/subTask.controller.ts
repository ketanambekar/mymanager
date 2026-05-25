import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { requireAuthUserId } from "../../utils/authUser";
import { subTaskService } from "./subTask.service";

export const subTaskController = {
  create: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await subTaskService.create(userId, req.validatedBody as never);
    res.status(201).json({ success: true, data });
  }),

  getAll: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await subTaskService.getAll(userId);
    res.status(200).json({ success: true, data });
  }),

  getById: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await subTaskService.getById(userId, id);
    res.status(200).json({ success: true, data });
  }),

  update: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await subTaskService.update(userId, id, req.validatedBody as never);
    res.status(200).json({ success: true, data });
  }),

  remove: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    await subTaskService.remove(userId, id);
    res.status(200).json({ success: true, message: "Subtask deleted" });
  }),
};
