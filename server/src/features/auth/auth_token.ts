import crypto from "node:crypto";
import jwt, { type SignOptions } from "jsonwebtoken";
import { env } from "../../config/env.js";

export type AccessTokenPayload = {
  sub: number;
  email: string;
  displayName: string;
  workspaceId: number;
};

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    algorithm: "HS256",
    expiresIn: env.JWT_ACCESS_EXPIRES_IN as SignOptions["expiresIn"],
    issuer: "mymanager-api",
    audience: "mymanager-client",
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const payload = jwt.verify(token, env.JWT_ACCESS_SECRET, {
    algorithms: ["HS256"],
    issuer: "mymanager-api",
    audience: "mymanager-client",
  });
  if (
    typeof payload === "string"
    || typeof payload.sub !== "number"
    || typeof payload.email !== "string"
    || typeof payload.displayName !== "string"
    || typeof payload.workspaceId !== "number"
  ) {
    throw new Error("Invalid access token payload");
  }
  return { sub: payload.sub, email: payload.email, displayName: payload.displayName, workspaceId: payload.workspaceId };
}

export function generateRefreshToken(): string {
  return crypto.randomBytes(48).toString("base64url");
}

export function hashRefreshToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}