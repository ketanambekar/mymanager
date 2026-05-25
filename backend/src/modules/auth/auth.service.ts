import crypto from "crypto";
import { OAuth2Client } from "google-auth-library";
import { AuthProvider, Prisma } from "@prisma/client";
import { env } from "../../config/env";
import { prisma } from "../../lib/prisma";
import { AppError } from "../../utils/appError";
import { AuthTokens, LoginWithGoogleDto } from "./auth.dto";
import { generateRefreshToken, hashRefreshToken, signAccessToken } from "./auth.token";

type AuthUserProfile = {
  id: number;
  email: string;
  name: string;
  avatarUrl: string | null;
  authProvider: AuthProvider;
  emailVerifiedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt: Date | null;
  isActive: boolean;
};

const authUserSelect = {
  id: true,
  email: true,
  name: true,
  avatarUrl: true,
  authProvider: true,
  emailVerifiedAt: true,
  createdAt: true,
  updatedAt: true,
  lastLoginAt: true,
  isActive: true,
} satisfies Prisma.UserSelect;

const oauthClient = new OAuth2Client(env.GOOGLE_CLIENT_ID);

function addDays(base: Date, days: number): Date {
  const value = new Date(base);
  value.setDate(value.getDate() + days);
  return value;
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function accessPayloadFromUser(user: { id: number; email: string; name: string; avatarUrl: string | null }) {
  return {
    sub: user.id,
    email: user.email,
    name: user.name,
    avatarUrl: user.avatarUrl,
    provider: "GOOGLE" as const,
  };
}

async function ensureGoogleUser(payload: LoginWithGoogleDto): Promise<AuthUserProfile> {
  let ticket;

  try {
    ticket = await oauthClient.verifyIdToken({
      idToken: payload.credential,
      audience: env.GOOGLE_CLIENT_ID,
    });
  } catch {
    throw new AppError("Google token verification failed. Check GOOGLE_CLIENT_ID and OAuth client configuration.", 401);
  }

  const googlePayload = ticket.getPayload();

  if (!googlePayload?.sub || !googlePayload.email || !googlePayload.name) {
    throw new AppError("Invalid Google profile", 401);
  }

  if (!googlePayload.email_verified) {
    throw new AppError("Google email is not verified", 401);
  }

  const email = normalizeEmail(googlePayload.email);

  const existingUser = await prisma.user.findFirst({
    where: {
      OR: [{ googleId: googlePayload.sub }, { email }],
    },
    select: {
      id: true,
      isActive: true,
    },
  });

  const user = existingUser
    ? await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          googleId: googlePayload.sub,
          email,
          name: googlePayload.name,
          avatarUrl: googlePayload.picture ?? null,
          authProvider: AuthProvider.GOOGLE,
          emailVerifiedAt: new Date(),
          lastLoginAt: new Date(),
          isActive: true,
        },
        select: authUserSelect,
      })
    : await prisma.user.create({
        data: {
          googleId: googlePayload.sub,
          email,
          name: googlePayload.name,
          avatarUrl: googlePayload.picture ?? null,
          authProvider: AuthProvider.GOOGLE,
          emailVerifiedAt: new Date(),
          lastLoginAt: new Date(),
          isActive: true,
        },
        select: authUserSelect,
      });

  if (!user.isActive) {
    throw new AppError("Account is deactivated", 403);
  }

  return user;
}

async function createSessionTx(
  tx: Prisma.TransactionClient,
  user: { id: number; email: string; name: string; avatarUrl: string | null },
  options?: { familyId?: string },
): Promise<AuthTokens & { sessionId: number }> {
  const accessToken = signAccessToken(accessPayloadFromUser(user));
  const refreshToken = generateRefreshToken();
  const familyId = options?.familyId ?? crypto.randomUUID();

  const session = await tx.refreshSession.create({
    data: {
      userId: user.id,
      tokenHash: hashRefreshToken(refreshToken),
      familyId,
      expiresAt: addDays(new Date(), env.REFRESH_TOKEN_EXPIRES_DAYS),
    },
  });

  return {
    sessionId: session.id,
    accessToken,
    refreshToken,
    accessTokenExpiresIn: env.JWT_ACCESS_EXPIRES_IN,
  };
}

export const authService = {
  async loginWithGoogle(payload: LoginWithGoogleDto): Promise<{ user: AuthUserProfile; tokens: AuthTokens }> {
    const user = await ensureGoogleUser(payload);
    const tokens = await prisma.$transaction((tx) => createSessionTx(tx, user));
    return { user, tokens };
  },

  async refresh(rawRefreshToken: string): Promise<{ user: AuthUserProfile; tokens: AuthTokens }> {
    const incomingHash = hashRefreshToken(rawRefreshToken);
    const activeSession = await prisma.refreshSession.findFirst({
      where: {
        tokenHash: incomingHash,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
      include: {
        user: {
          select: authUserSelect,
        },
      },
    });

    if (!activeSession?.user || !activeSession.user.isActive) {
      throw new AppError("Session expired", 401);
    }

    const user = activeSession.user;

    const tokens = await prisma.$transaction(async (tx) => {
      await tx.refreshSession.update({
        where: { id: activeSession.id },
        data: { revokedAt: new Date(), revokeReason: "ROTATED" },
      });

      const nextTokens = await createSessionTx(tx, user, { familyId: activeSession.familyId });

      await tx.refreshSession.update({
        where: { id: activeSession.id },
        data: { replacedBySessionId: nextTokens.sessionId },
      });

      return nextTokens;
    });

    return { user, tokens };
  },

  async logout(rawRefreshToken: string | undefined): Promise<void> {
    if (!rawRefreshToken) {
      return;
    }

    await prisma.refreshSession.updateMany({
      where: {
        tokenHash: hashRefreshToken(rawRefreshToken),
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
        revokeReason: "LOGOUT",
      },
    });
  },

  async getCurrentUserById(userId: number): Promise<AuthUserProfile> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: authUserSelect,
    });

    if (!user) {
      throw new AppError("User not found", 404);
    }

    return user;
  },
};
