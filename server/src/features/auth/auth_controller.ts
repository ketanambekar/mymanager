import type { Request, Response } from "express";
import { env } from "../../config/env.js";
import { AppError } from "../../shared/app_error.js";
import { asyncHandler } from "../../shared/async_handler.js";
import { authenticatedUser } from "./auth_context.js";
import { authService } from "./auth_service.js";
import { deviceMetadata, deviceService } from "./device_service.js";
import { qrLoginService } from "./qr_login_service.js";

const cookieOptions = () => ({ httpOnly: true, secure: env.NODE_ENV === "production", sameSite: "lax" as const, path: "/api/v1/auth", maxAge: env.REFRESH_TOKEN_EXPIRES_DAYS * 86400000 });
const refreshToken = (request: Request) => (request.cookies as Record<string, string> | undefined)?.[env.REFRESH_TOKEN_COOKIE_NAME];

function sendAuth(response: Response, result: Awaited<ReturnType<typeof authService.loginWithGoogle>>) {
  response.cookie(env.REFRESH_TOKEN_COOKIE_NAME, result.tokens.refreshToken, cookieOptions());
  response.status(200).json({ success: true, data: { user: result.user, accessToken: result.tokens.accessToken, accessTokenExpiresIn: result.tokens.accessTokenExpiresIn } });
}

export const authController = {
  login: asyncHandler(async (request, response) => {
    const { credential } = request.validatedBody as { credential: string };
    sendAuth(response, await authService.loginWithGoogle(credential, deviceMetadata(request.header("user-agent"))));
  }),
  refresh: asyncHandler(async (request, response) => {
    const token = refreshToken(request);
    if (!token) throw new AppError("REFRESH_TOKEN_MISSING", "Refresh token is missing", 401);
    sendAuth(response, await authService.refresh(token));
  }),
  logout: asyncHandler(async (request, response) => {
    await authService.logout(refreshToken(request));
    response.clearCookie(env.REFRESH_TOKEN_COOKIE_NAME, cookieOptions());
    response.status(200).json({ success: true, data: { message: "Logged out" } });
  }),
  session: asyncHandler(async (request, response) => {
    const auth = authenticatedUser(request);
    response.status(200).json({ success: true, data: await authService.currentUser(auth.sub) });
  }),
  devices: asyncHandler(async (request, response) => {
    response.json({ success: true, data: await deviceService.list(authenticatedUser(request)) });
  }),
  revokeDevice: asyncHandler(async (request, response) => {
    const { deviceId } = request.validatedParams as { deviceId: string };
    const result = await deviceService.revoke(authenticatedUser(request), deviceId);
    if (result.isCurrent) response.clearCookie(env.REFRESH_TOKEN_COOKIE_NAME, cookieOptions());
    response.json({ success: true, data: result });
  }),
  createChallenge: asyncHandler(async (request, response) => {
    const { deviceName } = request.validatedBody as { deviceName?: string };
    response.status(201).json({ success: true, data: await qrLoginService.create(deviceMetadata(request.header("user-agent"), deviceName)) });
  }),
  lookupChallenge: asyncHandler(async (request, response) => {
    const { code } = request.validatedBody as { code: string };
    response.json({ success: true, data: await qrLoginService.lookup(code) });
  }),
  decideChallenge: asyncHandler(async (request, response) => {
    const { challengeId } = request.validatedParams as { challengeId: string };
    const { code, decision } = request.validatedBody as { code: string; decision: "approve" | "deny" };
    response.json({ success: true, data: await qrLoginService.decide(authenticatedUser(request), challengeId, code, decision) });
  }),
  challengeStatus: asyncHandler(async (request, response) => {
    const { challengeId } = request.validatedParams as { challengeId: string };
    const { pollToken } = request.validatedBody as { pollToken: string };
    response.json({ success: true, data: await qrLoginService.status(challengeId, pollToken) });
  }),
  cancelChallenge: asyncHandler(async (request, response) => {
    const { challengeId } = request.validatedParams as { challengeId: string };
    const { pollToken } = request.validatedBody as { pollToken: string };
    response.json({ success: true, data: await qrLoginService.cancel(challengeId, pollToken) });
  }),
  consumeChallenge: asyncHandler(async (request, response) => {
    const { challengeId } = request.validatedParams as { challengeId: string };
    const { pollToken } = request.validatedBody as { pollToken: string };
    sendAuth(response, await qrLoginService.consume(challengeId, pollToken));
  }),
};