import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { requireAuthUserId } from "../../utils/authUser";
import { projectTypeService } from "./projectType.service";

export const projectTypeController = {
  create: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await projectTypeService.create(userId, req.validatedBody as never);
    res.status(201).json({ success: true, data });
  }),

  getAll: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await projectTypeService.getAll(userId);
    res.status(200).json({ success: true, data });
  }),

  getById: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await projectTypeService.getById(userId, id);
    res.status(200).json({ success: true, data });
  }),

  update: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await projectTypeService.update(userId, id, req.validatedBody as never);
    res.status(200).json({ success: true, data });
  }),

  remove: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    await projectTypeService.remove(userId, id);
    res.status(200).json({ success: true, message: "Project type deleted" });
  }),
};
