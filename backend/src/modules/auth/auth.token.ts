import crypto from "crypto";
import jwt from "jsonwebtoken";
import { env } from "../../config/env";

export type AccessTokenPayload = {
  sub: number;
  email: string;
  name: string;
  avatarUrl?: string | null;
  provider: "GOOGLE";
};

export function signAccessToken(payload: AccessTokenPayload): string {
  const expiresIn = env.JWT_ACCESS_EXPIRES_IN as jwt.SignOptions["expiresIn"];

  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn,
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as jwt.JwtPayload;

  return {
    sub: Number(decoded.sub),
    email: String(decoded.email),
    name: String(decoded.name),
    avatarUrl: decoded.avatarUrl ? String(decoded.avatarUrl) : null,
    provider: "GOOGLE",
  };
}

export function generateRefreshToken(): string {
  return crypto.randomBytes(48).toString("hex");
}

export function hashRefreshToken(rawToken: string): string {
  return crypto.createHash("sha256").update(rawToken).digest("hex");
}
