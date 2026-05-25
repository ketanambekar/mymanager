import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { authService } from "./auth.service";
import { clearRefreshCookieOptions, refreshCookieOptions } from "./auth.cookies";
import { env } from "../../config/env";
import { AppError } from "../../utils/appError";

function getRefreshTokenFromCookie(req: Request): string | undefined {
  const cookies = req.cookies as Record<string, string> | undefined;
  return cookies?.[env.REFRESH_TOKEN_COOKIE_NAME];
}

function currentUserIdOrThrow(req: Request): number {
  if (!req.auth?.user) {
    throw new AppError("Authentication required", 401);
  }

  return req.auth.user.id;
}

export const authController = {
  loginWithGoogle: asyncHandler(async (req: Request, res: Response) => {
    const { user, tokens } = await authService.loginWithGoogle(req.validatedBody as never);

    res.cookie(env.REFRESH_TOKEN_COOKIE_NAME, tokens.refreshToken, refreshCookieOptions());
    res.status(200).json({
      success: true,
      data: {
        user,
        accessToken: tokens.accessToken,
        accessTokenExpiresIn: tokens.accessTokenExpiresIn,
      },
    });
  }),

  refreshToken: asyncHandler(async (req: Request, res: Response) => {
    const refreshToken = getRefreshTokenFromCookie(req);
    if (!refreshToken) {
      throw new AppError("Refresh token is missing", 401);
    }

    const { user, tokens } = await authService.refresh(refreshToken);

    res.cookie(env.REFRESH_TOKEN_COOKIE_NAME, tokens.refreshToken, refreshCookieOptions());
    res.status(200).json({
      success: true,
      data: {
        user,
        accessToken: tokens.accessToken,
        accessTokenExpiresIn: tokens.accessTokenExpiresIn,
      },
    });
  }),

  logout: asyncHandler(async (req: Request, res: Response) => {
    await authService.logout(getRefreshTokenFromCookie(req));
    res.clearCookie(env.REFRESH_TOKEN_COOKIE_NAME, clearRefreshCookieOptions());
    res.status(200).json({ success: true, message: "Logged out" });
  }),

  getCurrentUser: asyncHandler(async (req: Request, res: Response) => {
    const userId = currentUserIdOrThrow(req);
    const user = await authService.getCurrentUserById(userId);
    res.status(200).json({ success: true, data: user });
  }),
};
