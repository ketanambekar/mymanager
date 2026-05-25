import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { requireAuthUserId } from "../../utils/authUser";
import { projectColorService } from "./projectColor.service";

export const projectColorController = {
  create: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await projectColorService.create(userId, req.validatedBody as never);
    res.status(201).json({ success: true, data });
  }),

  getAll: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const data = await projectColorService.getAll(userId);
    res.status(200).json({ success: true, data });
  }),

  getById: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await projectColorService.getById(userId, id);
    res.status(200).json({ success: true, data });
  }),

  update: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    const data = await projectColorService.update(userId, id, req.validatedBody as never);
    res.status(200).json({ success: true, data });
  }),

  remove: asyncHandler(async (req: Request, res: Response) => {
    const userId = requireAuthUserId(req);
    const { id } = req.validatedParams as { id: number };
    await projectColorService.remove(userId, id);
    res.status(200).json({ success: true, message: "Project color deleted" });
  }),
};
