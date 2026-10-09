import crypto from "node:crypto";
import type { LoginChallenge, Prisma } from "@prisma/client";
import { env } from "../../config/env.js";
import { prisma } from "../../database/prisma.js";
import { AppError } from "../../shared/app_error.js";
import { issueSession, userView } from "./auth_service.js";
import { generateRefreshToken, hashRefreshToken, type AccessTokenPayload } from "./auth_token.js";
import { assertActiveDevice, type DeviceMetadata } from "./device_service.js";

export const challengeLifetimeMs = 5 * 60 * 1000;

function hashCode(code: string) {
  return crypto.createHmac("sha256", env.JWT_ACCESS_SECRET).update(`qr-login:${code}`).digest("hex");
}

export function challengeStatus(challenge: LoginChallenge, now = new Date()) {
  if (challenge.consumedAt) return "consumed";
  if (challenge.deniedAt) return "denied";
  if (challenge.expiresAt <= now) return "expired";
  return challenge.approvedAt ? "approved" : "pending";
}

function challengeView(challenge: LoginChallenge) {
  return {
    challengeId: challenge.id, deviceName: challenge.deviceName, userAgent: challenge.userAgent,
    createdAt: challenge.createdAt, expiresAt: challenge.expiresAt, status: challengeStatus(challenge),
  };
}

async function ownedChallenge(db: Prisma.TransactionClient, challengeId: string, pollToken: string) {
  const challenge = await db.loginChallenge.findFirst({ where: { id: challengeId, pollTokenHash: hashRefreshToken(pollToken) } });
  if (!challenge) throw new AppError("LOGIN_CHALLENGE_NOT_FOUND", "Login request not found", 404);
  return challenge;
}

async function lockApprover(db: Prisma.TransactionClient, auth: AccessTokenPayload) {
  await assertActiveDevice(auth, db);
  const active = await db.deviceSession.updateMany({
    where: { id: auth.deviceId, userId: auth.sub, revokedAt: null, expiresAt: { gt: new Date() }, user: { status: "ACTIVE" } },
    data: { lastUsedAt: new Date() },
  });
  if (!active.count) throw new AppError("SESSION_EXPIRED", "Session expired", 401);
}

export const qrLoginService = {
  async create(metadata: DeviceMetadata) {
    const code = crypto.randomInt(0, 10_000_000_000).toString().padStart(10, "0");
    const pollToken = generateRefreshToken();
    const challenge = await prisma.loginChallenge.create({
      data: {
        id: crypto.randomUUID(), codeHash: hashCode(code), pollTokenHash: hashRefreshToken(pollToken),
        ...metadata, expiresAt: new Date(Date.now() + challengeLifetimeMs),
      },
    });
    return {
      ...challengeView(challenge), code, pollToken, pollIntervalSeconds: 10,
      qrPayload: JSON.stringify({ type: "mymanager-login", version: 1, code }),
    };
  },

  async lookup(code: string) {
    const challenge = await prisma.loginChallenge.findUnique({ where: { codeHash: hashCode(code) } });
    if (!challenge || challengeStatus(challenge) !== "pending") {
      throw new AppError("LOGIN_CODE_INVALID", "Code is invalid, expired, or already used", 404);
    }
    return challengeView(challenge);
  },

  async decide(auth: AccessTokenPayload, challengeId: string, code: string, decision: "approve" | "deny") {
    return prisma.$transaction(async (db) => {
      await lockApprover(db, auth);
      const now = new Date();
      const changed = await db.loginChallenge.updateMany({
        where: { id: challengeId, codeHash: hashCode(code), expiresAt: { gt: now }, approvedAt: null, deniedAt: null, consumedAt: null },
        data: decision === "approve"
          ? { approvedAt: now, approvedByUserId: auth.sub, approvedDeviceId: auth.deviceId }
          : { deniedAt: now },
      });
      if (!changed.count) throw new AppError("LOGIN_CHALLENGE_UNAVAILABLE", "Login request is no longer available", 409);
      return { challengeId, status: decision === "approve" ? "approved" : "denied" };
    });
  },

  async status(challengeId: string, pollToken: string) {
    const challenge = await ownedChallenge(prisma, challengeId, pollToken);
    return { challengeId, status: challengeStatus(challenge), expiresAt: challenge.expiresAt };
  },

  async cancel(challengeId: string, pollToken: string) {
    await prisma.$transaction(async (db) => {
      await ownedChallenge(db, challengeId, pollToken);
      const changed = await db.loginChallenge.updateMany({
        where: { id: challengeId, consumedAt: null, deniedAt: null, expiresAt: { gt: new Date() } },
        data: { deniedAt: new Date() },
      });
      if (!changed.count) throw new AppError("LOGIN_CHALLENGE_UNAVAILABLE", "Login request is no longer available", 409);
    });
    return { challengeId, status: "denied" };
  },

  async consume(challengeId: string, pollToken: string) {
    return prisma.$transaction(async (db) => {
      const challenge = await ownedChallenge(db, challengeId, pollToken);
      if (challengeStatus(challenge) !== "approved" || !challenge.approvedByUserId || !challenge.approvedDeviceId) {
        throw new AppError("LOGIN_CHALLENGE_UNAVAILABLE", "Login request is not approved or no longer available", 409);
      }
      const user = await db.user.findUnique({ where: { id: challenge.approvedByUserId }, select: userView });
      if (!user || user.status !== "ACTIVE") throw new AppError("ACCOUNT_DISABLED", "Account is disabled", 403);
      if (!user.workspace) throw new AppError("WORKSPACE_NOT_FOUND", "Workspace not found", 500);
      await lockApprover(db, { sub: user.id, email: user.email, displayName: user.displayName, workspaceId: user.workspace.id, deviceId: challenge.approvedDeviceId });
      const claimed = await db.loginChallenge.updateMany({
        where: { id: challengeId, approvedAt: { not: null }, consumedAt: null, deniedAt: null, expiresAt: { gt: new Date() } },
        data: { consumedAt: new Date() },
      });
      if (!claimed.count) throw new AppError("LOGIN_CHALLENGE_UNAVAILABLE", "Login request is no longer available", 409);
      const loggedInUser = await db.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date() }, select: userView });
      return { user: loggedInUser, tokens: await issueSession(db, loggedInUser, { deviceName: challenge.deviceName, userAgent: challenge.userAgent }) };
    });
  },
};
