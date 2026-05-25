import { CookieOptions } from "express";
import { env } from "../../config/env";

export function refreshCookieOptions(): CookieOptions {
  const isProduction = env.NODE_ENV === "production";
  const sameSite: CookieOptions["sameSite"] = isProduction ? "none" : "lax";

  return {
    httpOnly: true,
    secure: isProduction,
    sameSite,
    maxAge: env.REFRESH_TOKEN_EXPIRES_DAYS * 24 * 60 * 60 * 1000,
    path: "/api/v1/auth",
  };
}

export function clearRefreshCookieOptions(): CookieOptions {
  const isProduction = env.NODE_ENV === "production";
  const sameSite: CookieOptions["sameSite"] = isProduction ? "none" : "lax";

  return {
    httpOnly: true,
    secure: isProduction,
    sameSite,
    path: "/api/v1/auth",
  };
}
