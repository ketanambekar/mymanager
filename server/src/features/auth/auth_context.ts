import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../shared/app_error.js";
import { verifyAccessToken } from "./auth_token.js";
import { assertActiveDevice } from "./device_service.js";
import { prisma } from "../../database/prisma.js";

export function attachAuthContext(request: Request, _response: Response, next: NextFunction): void {
  const authorization = request.headers.authorization;
  const token = authorization?.startsWith("Bearer ") ? authorization.slice(7).trim() : null;
  request.auth = null;
  if (token) {
    try {
      request.auth = verifyAccessToken(token);
    } catch {
      request.auth = null;
    }
  }
  next();
}

export async function requireAuth(request: Request, _response: Response, next: NextFunction): Promise<void> {
  if (!request.auth) {
    next(new AppError("AUTHENTICATION_REQUIRED", "Authentication required", 401));
    return;
  }
  try {
    const device = await assertActiveDevice(request.auth);
    const now = new Date();
    if (now.getTime() - device.lastUsedAt.getTime() >= 60000) {
      await prisma.deviceSession.updateMany({ where: { id: device.id, revokedAt: null }, data: { lastUsedAt: now } });
    }
    next();
  } catch (error) {
    next(error);
  }
}

export function authenticatedUser(request: Request): AccessTokenPayload {
  if (!request.auth) throw new AppError("AUTHENTICATION_REQUIRED", "Authentication required", 401);
  return request.auth;
}

import type { AccessTokenPayload } from "./auth_token.js";