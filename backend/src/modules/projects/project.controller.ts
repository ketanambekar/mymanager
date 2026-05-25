import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { requireAuthUserId } from "../../utils/authUser";
import { projectService } from "./project.service";

export const projectController = {
  create: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await projectService.create(userId, req.validatedBody as never);
    res.status(201).json({ success: true, data });
  }),

  getAll: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await projectService.getAll(userId);
    res.status(200).json({ success: true, data });
  }),

  getById: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await projectService.getById(userId, id);
    res.status(200).json({ success: true, data });
  }),

  update: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await projectService.update(userId, id, req.validatedBody as never);
    res.status(200).json({ success: true, data });
  }),

  remove: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    await projectService.remove(userId, id);
    res.status(200).json({ success: true, message: "Project deleted" });
  }),
};
