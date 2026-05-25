import { NextFunction, Request, Response } from "express";
import { verifyAccessToken } from "../modules/auth/auth.token";
import { AppError } from "../utils/appError";

export function attachAuthContext(req: Request, _res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  const bearerToken = authHeader?.startsWith("Bearer ") ? authHeader.slice("Bearer ".length).trim() : null;

  if (!bearerToken) {
    req.auth = null;
    next();
    return;
  }

  try {
    const payload = verifyAccessToken(bearerToken);
    req.auth = {
      accessToken: bearerToken,
      user: {
        id: payload.sub,
        email: payload.email,
        name: payload.name,
        avatarUrl: payload.avatarUrl,
        provider: "GOOGLE",
      },
    };
  } catch {
    req.auth = null;
  }

  next();
}

export function requireAuth(req: Request, _res: Response, next: NextFunction): void {
  if (!req.auth?.user) {
    next(new AppError("Authentication required", 401));
    return;
  }

  next();
}

export function optionalAuth(_req: Request, _res: Response, next: NextFunction): void {
  next();
}