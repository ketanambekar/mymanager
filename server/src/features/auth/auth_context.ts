import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../shared/app_error.js";
import { verifyAccessToken } from "./auth_token.js";

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

export function requireAuth(request: Request, _response: Response, next: NextFunction): void {
  if (!request.auth) {
    next(new AppError("AUTHENTICATION_REQUIRED", "Authentication required", 401));
    return;
  }
  next();
}

export function authenticatedUser(request: Request): AccessTokenPayload {
  if (!request.auth) throw new AppError("AUTHENTICATION_REQUIRED", "Authentication required", 401);
  return request.auth;
}

import type { AccessTokenPayload } from "./auth_token.js";