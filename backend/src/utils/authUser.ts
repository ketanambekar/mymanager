import { Request } from "express";
import { AppError } from "./appError";

export function requireAuthUserId(req: Request): number {
  const userId = req.auth?.user?.id;
  if (!userId) {
    throw new AppError("Authentication required", 401);
  }

  return userId;
}
