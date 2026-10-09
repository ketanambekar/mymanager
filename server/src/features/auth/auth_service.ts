import crypto from "node:crypto";
import { OAuth2Client } from "google-auth-library";
import { UserStatus, type Prisma } from "@prisma/client";
import { env } from "../../config/env.js";
import { prisma } from "../../database/prisma.js";
import { AppError } from "../../shared/app_error.js";
import { generateRefreshToken, hashRefreshToken, signAccessToken } from "./auth_token.js";
import { deviceMetadata, revokeDevice, type DeviceMetadata } from "./device_service.js";

const googleClient = new OAuth2Client(env.GOOGLE_CLIENT_ID);
export const userView = {
  id: true,
  email: true,
  displayName: true,
  avatarUrl: true,
  status: true,
  lastLoginAt: true,
  workspace: true,
  preference: true,
} satisfies Prisma.UserSelect;

function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setUTCDate(result.getUTCDate() + days);
  return result;
}

export async function issueSession(
  db: Prisma.TransactionClient,
  user: { id: number; email: string; displayName: string; workspace: { id: number } | null },
  metadata: DeviceMetadata,
  familyId?: string,
) {
  if (!user.workspace) throw new AppError("WORKSPACE_NOT_FOUND", "Workspace not found", 500);
  const deviceId = familyId ?? crypto.randomUUID();
  const expiresAt = addDays(new Date(), env.REFRESH_TOKEN_EXPIRES_DAYS);
  if (!familyId) {
    await db.deviceSession.create({ data: { id: deviceId, userId: user.id, ...metadata, expiresAt } });
  }
  const refreshToken = generateRefreshToken();
  const session = await db.refreshSession.create({
    data: { userId: user.id, tokenHash: hashRefreshToken(refreshToken), familyId: deviceId, expiresAt },
  });
  const accessToken = signAccessToken({ sub: user.id, email: user.email, displayName: user.displayName, workspaceId: user.workspace.id, deviceId });
  return { sessionId: session.id, accessToken, refreshToken, accessTokenExpiresIn: env.JWT_ACCESS_EXPIRES_IN };
}

export const authService = {
  async loginWithGoogle(credential: string, metadata: DeviceMetadata = deviceMetadata()) {
    let payload;
    try {
      const ticket = await googleClient.verifyIdToken({ idToken: credential, audience: env.GOOGLE_CLIENT_ID });
      payload = ticket.getPayload();
    } catch {
      throw new AppError("GOOGLE_TOKEN_INVALID", "Google token verification failed", 401);
    }
    if (!payload?.sub || !payload.email || !payload.name || !payload.email_verified) {
      throw new AppError("GOOGLE_PROFILE_INVALID", "A verified Google profile is required", 401);
    }
    const email = payload.email.trim().toLowerCase();
    const now = new Date();
    const existing = await prisma.user.findFirst({ where: { OR: [{ googleSubject: payload.sub }, { email }] } });
    const user = existing
      ? await prisma.user.update({
          where: { id: existing.id },
          data: { googleSubject: payload.sub, email, displayName: payload.name, avatarUrl: payload.picture ?? null, emailVerifiedAt: now, lastLoginAt: now },
          select: userView,
        })
      : await prisma.user.create({
          data: {
            googleSubject: payload.sub,
            email,
            displayName: payload.name,
            avatarUrl: payload.picture ?? null,
            emailVerifiedAt: now,
            lastLoginAt: now,
            workspace: { create: {} },
            preference: { create: {} },
          },
          select: userView,
        });
    if (user.status !== UserStatus.ACTIVE) throw new AppError("ACCOUNT_DISABLED", "Account is disabled", 403);
    return { user, tokens: await prisma.$transaction((db) => issueSession(db, user, metadata)) };
  },

  async refresh(rawToken: string) {
    const tokenHash = hashRefreshToken(rawToken);
    const result = await prisma.$transaction(async (db) => {
      const session = await db.refreshSession.findUnique({ where: { tokenHash }, include: { user: { select: userView } } });
      if (!session || session.expiresAt <= new Date()) throw new AppError("SESSION_EXPIRED", "Session expired", 401);
      if (session.user.status !== UserStatus.ACTIVE) throw new AppError("ACCOUNT_DISABLED", "Account is disabled", 403);
      const now = new Date();
      const expiresAt = addDays(now, env.REFRESH_TOKEN_EXPIRES_DAYS);
      const active = await db.deviceSession.updateMany({
        where: { id: session.familyId, userId: session.userId, revokedAt: null, expiresAt: { gt: now } },
        data: { lastUsedAt: now, expiresAt },
      });
      if (!active.count) throw new AppError("SESSION_EXPIRED", "Session expired", 401);
      const claimed = await db.refreshSession.updateMany({
        where: { id: session.id, revokedAt: null },
        data: { revokedAt: now, revokeReason: "ROTATED" },
      });
      if (!claimed.count) {
        await revokeDevice(db, session.familyId, "REUSE_DETECTED");
        return null;
      }
      const next = await issueSession(db, session.user, deviceMetadata(), session.familyId);
      await db.refreshSession.update({ where: { id: session.id }, data: { replacedBySessionId: next.sessionId } });
      return { user: session.user, tokens: next };
    });
    if (!result) throw new AppError("SESSION_REUSE_DETECTED", "Session expired", 401);
    return result;
  },

  async logout(rawToken?: string) {
    if (!rawToken) return;
    await prisma.$transaction(async (db) => {
      const session = await db.refreshSession.findUnique({ where: { tokenHash: hashRefreshToken(rawToken) } });
      if (session) await revokeDevice(db, session.familyId, "LOGOUT");
    });
  },

  async currentUser(userId: number) {
    const user = await prisma.user.findFirst({ where: { id: userId, status: UserStatus.ACTIVE }, select: userView });
    if (!user) throw new AppError("USER_NOT_FOUND", "User not found", 404);
    return user;
  },
};