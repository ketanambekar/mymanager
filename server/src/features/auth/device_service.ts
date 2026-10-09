import type { Prisma } from "@prisma/client";
import { prisma } from "../../database/prisma.js";
import { AppError } from "../../shared/app_error.js";
import type { AccessTokenPayload } from "./auth_token.js";

export type DeviceMetadata = { deviceName: string; userAgent: string | null };

export function deviceMetadata(userAgent?: string, deviceName?: string): DeviceMetadata {
  const agent = userAgent?.slice(0, 512) || null;
  const browser = /Edg\//.test(agent ?? "") ? "Edge" : /Firefox\//.test(agent ?? "") ? "Firefox"
    : /Chrome\//.test(agent ?? "") ? "Chrome" : /Safari\//.test(agent ?? "") ? "Safari" : "Browser or app";
  const platform = /Android/.test(agent ?? "") ? "Android" : /iPhone|iPad/.test(agent ?? "") ? "iOS"
    : /Windows/.test(agent ?? "") ? "Windows" : /Macintosh/.test(agent ?? "") ? "macOS"
    : /Linux/.test(agent ?? "") ? "Linux" : null;
  return { deviceName: deviceName ?? (platform ? `${browser} on ${platform}` : browser), userAgent: agent };
}

export async function assertActiveDevice(auth: AccessTokenPayload, db: Prisma.TransactionClient = prisma) {
  if (!auth.deviceId) throw new AppError("SESSION_EXPIRED", "Refresh your session to continue", 401);
  const device = await db.deviceSession.findFirst({
    where: { id: auth.deviceId, userId: auth.sub, revokedAt: null, expiresAt: { gt: new Date() }, user: { status: "ACTIVE", workspace: { id: auth.workspaceId } } },
  });
  if (!device) throw new AppError("SESSION_EXPIRED", "Session expired", 401);
  return device;
}

export async function revokeDevice(db: Prisma.TransactionClient, deviceId: string, reason: string) {
  const now = new Date();
  await db.deviceSession.updateMany({ where: { id: deviceId, revokedAt: null }, data: { revokedAt: now, revokeReason: reason } });
  await db.refreshSession.updateMany({ where: { familyId: deviceId, revokedAt: null }, data: { revokedAt: now, revokeReason: reason } });
}

export const deviceService = {
  async list(auth: AccessTokenPayload) {
    const devices = await prisma.deviceSession.findMany({
      where: { userId: auth.sub, revokedAt: null, expiresAt: { gt: new Date() } },
      orderBy: [{ lastUsedAt: "desc" }, { id: "asc" }],
      select: { id: true, deviceName: true, userAgent: true, createdAt: true, lastUsedAt: true, expiresAt: true },
    });
    return { activeCount: devices.length, devices: devices.map((device) => ({ ...device, isCurrent: device.id === auth.deviceId })) };
  },
  async revoke(auth: AccessTokenPayload, deviceId: string) {
    await prisma.$transaction(async (db) => {
      const device = await db.deviceSession.findFirst({ where: { id: deviceId, userId: auth.sub } });
      if (!device) throw new AppError("DEVICE_NOT_FOUND", "Device session not found", 404);
      await revokeDevice(db, device.id, "REMOTE_LOGOUT");
    });
    return { deviceId, isCurrent: deviceId === auth.deviceId };
  },
};
