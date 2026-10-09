import assert from "node:assert/strict";
import crypto from "node:crypto";
import { once } from "node:events";
import { execFileSync } from "node:child_process";
import { cp, mkdtemp, mkdir, rm } from "node:fs/promises";
import { createRequire } from "node:module";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { PrismaClient } from "@prisma/client";
import dotenv from "dotenv";
import { LoginTicket, OAuth2Client } from "google-auth-library";
import { z } from "zod";

const authDataSchema = z.object({
  user: z.object({ id: z.number(), email: z.string(), lastLoginAt: z.string().nullable() }).passthrough(),
  accessToken: z.string(), accessTokenExpiresIn: z.string(),
}).strict();
const previewSchema = z.object({
  challengeId: z.uuid(), deviceName: z.string(), userAgent: z.string().nullable(),
  createdAt: z.string(), expiresAt: z.string(), status: z.string(),
}).strict();
const createdSchema = previewSchema.extend({
  code: z.string(), pollToken: z.string(), qrPayload: z.string(), pollIntervalSeconds: z.number(),
}).strict();
const decisionSchema = z.object({ challengeId: z.uuid(), status: z.string() }).strict();
const statusSchema = decisionSchema.extend({ expiresAt: z.string() }).strict();

async function readData<S extends z.ZodType>(response: Response, schema: S): Promise<z.output<S>> {
  const envelope = z.object({ success: z.literal(true), data: z.unknown() }).parse(await response.json());
  return schema.parse(envelope.data);
}

async function readErrorCode(response: Response) {
  return z.object({ success: z.literal(false), error: z.object({ code: z.string() }) }).parse(await response.json()).error.code;
}

test("QR login and device lifecycle on isolated MySQL", async (t) => {
  dotenv.config({ quiet: true });
  const originalUrl = process.env.DATABASE_URL ?? process.env.MYSQL_URL;
  assert.ok(originalUrl, "Configure a local DATABASE_URL before running integration tests");
  const url = new URL(originalUrl);
  assert.ok(["localhost", "127.0.0.1"].includes(url.hostname), "Integration tests only use local MySQL");
  const databaseName = `mymanager_auth_test_${crypto.randomBytes(8).toString("hex")}`;
  const admin = new PrismaClient({ datasourceUrl: originalUrl });
  const temporary = await mkdtemp(path.join(os.tmpdir(), "mymanager-auth-"));
  let db: PrismaClient | undefined;
  let databaseCreated = false;
  try {
    await admin.$executeRawUnsafe(`CREATE DATABASE \`${databaseName}\``);
    databaseCreated = true;
    url.pathname = `/${databaseName}`;
    process.env.DATABASE_URL = url.href;
    process.env.NODE_ENV = "test";
    process.env.GOOGLE_CLIENT_ID = "test.apps.googleusercontent.com";
    process.env.JWT_ACCESS_SECRET = "integration-test-secret-at-least-32-characters";
    process.env.FRONTEND_URL = "http://localhost:5173";
    const schemaDirectory = path.join(temporary, "prisma");
    const migrations = path.join(schemaDirectory, "migrations");
    await mkdir(migrations, { recursive: true });
    await cp(path.resolve("prisma", "schema.prisma"), path.join(schemaDirectory, "schema.prisma"));
    await cp(path.resolve("prisma", "migrations"), migrations, { recursive: true });
    const migrationName = "20261009080000_qr_device_sessions";
    await rm(path.join(migrations, migrationName), { recursive: true });
    const require = createRequire(path.resolve("package.json"));
    const deploy = (schema: string) => execFileSync(process.execPath, [
      require.resolve("prisma/build/index.js"), "migrate", "deploy", "--schema", schema,
    ], { env: process.env, stdio: "pipe" });
    deploy(path.join(schemaDirectory, "schema.prisma"));
    db = new PrismaClient({ datasourceUrl: url.href });
    const legacyUser = await db.user.create({
      data: { googleSubject: "legacy", email: "legacy@example.com", displayName: "Legacy", workspace: { create: {} }, preference: { create: {} } },
    });
    const legacyToken = crypto.randomBytes(48).toString("base64url");
    const legacyFamily = crypto.randomUUID();
    const legacySince = new Date(Date.now() - 86400000);
    await db.refreshSession.create({
      data: {
        userId: legacyUser.id, familyId: legacyFamily, tokenHash: crypto.createHash("sha256").update(legacyToken).digest("hex"),
        createdAt: legacySince, expiresAt: new Date(Date.now() + 86400000),
      },
    });
    const inactiveFamily = crypto.randomUUID();
    await db.refreshSession.create({
      data: { userId: legacyUser.id, familyId: inactiveFamily, tokenHash: "0".repeat(64), expiresAt: new Date(Date.now() - 1000) },
    });
    await cp(path.resolve("prisma", "migrations", migrationName), path.join(migrations, migrationName), { recursive: true });
    deploy(path.join(schemaDirectory, "schema.prisma"));

    const { prisma } = await import("../src/database/prisma.js");
    await db.$disconnect();
    db = prisma;
    const { authService, issueSession } = await import("../src/features/auth/auth_service.js");
    const { deviceService, deviceMetadata, assertActiveDevice } = await import("../src/features/auth/device_service.js");
    const { qrLoginService } = await import("../src/features/auth/qr_login_service.js");
    const { verifyAccessToken, hashRefreshToken } = await import("../src/features/auth/auth_token.js");
    const { app } = await import("../src/app.js");
    const googlePayload = {
      iss: "https://accounts.google.com", aud: process.env.GOOGLE_CLIENT_ID, iat: 1, exp: 9999999999,
      sub: "test-google-user", email: "google@example.com", email_verified: true, name: "Google Test",
    };
    t.mock.method(OAuth2Client.prototype, "verifyIdToken", async () => new LoginTicket("test", googlePayload));
    const server = app.listen(0, "127.0.0.1");
    await once(server, "listening");
    try {
      const address = server.address();
      assert.ok(address && typeof address !== "string");
      const base = `http://127.0.0.1:${address.port}/api/v1`;
      const call = (endpoint: string, body?: object, token?: string, method = "POST", cookie?: string) => fetch(`${base}${endpoint}`, {
        method, headers: {
          "content-type": "application/json", "user-agent": "Mozilla Windows Chrome/123",
          ...(token ? { authorization: `Bearer ${token}` } : {}), ...(cookie ? { cookie } : {}),
        }, body: body ? JSON.stringify(body) : undefined,
      });
      const user = await prisma.user.create({
        data: { googleSubject: "approver", email: "approver@example.com", displayName: "Approver", workspace: { create: {} }, preference: { create: {} } },
        include: { workspace: true },
      });
      const source = await prisma.$transaction((tx) => issueSession(tx, user, deviceMetadata("iPhone Safari/1")));
      const sourceAuth = verifyAccessToken(source.accessToken);
      const otherUser = await prisma.user.create({
        data: { googleSubject: "other", email: "other@example.com", displayName: "Other", workspace: { create: {} }, preference: { create: {} } },
        include: { workspace: true },
      });
      const other = await prisma.$transaction((tx) => issueSession(tx, otherUser, deviceMetadata()));

      await t.test("migration preserves legacy refresh login and stable active-since", async () => {
        const backfilled = await prisma.deviceSession.findUniqueOrThrow({ where: { id: legacyFamily } });
        assert.equal(backfilled.createdAt.getTime(), legacySince.getTime());
        assert.equal(backfilled.revokedAt, null);
        assert.ok((await prisma.deviceSession.findUniqueOrThrow({ where: { id: inactiveFamily } })).revokedAt);
        const refreshed = await authService.refresh(legacyToken);
        assert.equal(verifyAccessToken(refreshed.tokens.accessToken).deviceId, legacyFamily);
        assert.equal((await prisma.deviceSession.findUniqueOrThrow({ where: { id: legacyFamily } })).createdAt.getTime(), legacySince.getTime());
        const legacyAccess = await import("../src/features/auth/auth_token.js").then(({ signAccessToken }) =>
          signAccessToken({ sub: legacyUser.id, email: legacyUser.email, displayName: legacyUser.displayName, workspaceId: refreshed.user.workspace!.id }));
        assert.equal((await call("/auth/session", undefined, legacyAccess, "GET")).status, 401);
      });

      await t.test("Google login still returns the established cookie/token shape", async () => {
        const response = await call("/auth/google", { credential: "test-credential-at-least-twenty-characters" });
        assert.equal(response.status, 200);
        const result = await readData(response, authDataSchema);
        assert.equal(result.user.email, "google@example.com");
        assert.match(response.headers.get("set-cookie") ?? "", /HttpOnly/);
        assert.match(response.headers.get("set-cookie") ?? "", /SameSite=Lax/);
        assert.equal((await call("/auth/session", undefined, result.accessToken, "GET")).status, 200);
      });

      await t.test("QR/code approval issues tokens only to the requesting browser", async () => {
        const created = await call("/auth/qr/challenges", { deviceName: "Work laptop" });
        assert.equal(created.status, 201);
        assert.equal(created.headers.get("cache-control"), "no-store");
        const challenge = await readData(created, createdSchema);
        assert.match(challenge.code, /^\d{10}$/);
        assert.equal(challenge.pollToken.length, 64);
        assert.deepEqual(JSON.parse(challenge.qrPayload), { type: "mymanager-login", version: 1, code: challenge.code });
        const stored = await prisma.loginChallenge.findUniqueOrThrow({ where: { id: challenge.challengeId } });
        assert.notEqual(stored.codeHash, challenge.code);
        assert.equal(stored.pollTokenHash, hashRefreshToken(challenge.pollToken));
        assert.equal(stored.expiresAt.getTime() - stored.createdAt.getTime() <= 300000, true);
        assert.equal((await call("/auth/qr/lookup", { code: challenge.code })).status, 401);
        assert.equal((await call(`/auth/qr/challenges/${challenge.challengeId}/consume`, { pollToken: challenge.pollToken })).status, 409);
        assert.equal((await call(`/auth/qr/challenges/${challenge.challengeId}/status`, { pollToken: "x".repeat(64) })).status, 404);
        const lookedUp = await call("/auth/qr/lookup", { code: challenge.code }, source.accessToken);
        assert.equal(lookedUp.status, 200);
        const preview = await readData(lookedUp, previewSchema);
        assert.equal(preview.deviceName, "Work laptop");
        assert.equal("pollToken" in preview, false);
        const approval = await call(`/auth/qr/challenges/${challenge.challengeId}/decision`, { code: challenge.code, decision: "approve" }, source.accessToken);
        assert.equal(approval.status, 200);
        assert.equal("accessToken" in await readData(approval, decisionSchema), false);
        assert.equal(approval.headers.get("set-cookie"), null);
        const state = await readData(await call(`/auth/qr/challenges/${challenge.challengeId}/status`, { pollToken: challenge.pollToken }), statusSchema);
        assert.equal(state.status, "approved");
        assert.equal("user" in state, false);
        const consumed = await call(`/auth/qr/challenges/${challenge.challengeId}/consume`, { pollToken: challenge.pollToken });
        assert.equal(consumed.status, 200);
        assert.match(consumed.headers.get("set-cookie") ?? "", /HttpOnly/);
        const result = await readData(consumed, authDataSchema);
        assert.equal(result.user.id, user.id);
        assert.equal(result.user.lastLoginAt, (await prisma.user.findUniqueOrThrow({ where: { id: user.id } })).lastLoginAt?.toISOString());
        assert.equal((await call("/auth/session", undefined, result.accessToken, "GET")).status, 200);
        assert.equal((await call(`/auth/qr/challenges/${challenge.challengeId}/consume`, { pollToken: challenge.pollToken })).status, 409);
        const listed = await deviceService.list(sourceAuth);
        assert.equal(listed.activeCount, 2);
        assert.equal(listed.devices.filter((item) => item.isCurrent).length, 1);
        const target = listed.devices.find((item) => item.deviceName === "Work laptop")!;
        const denyOther = await call(`/auth/devices/${target.id}`, undefined, other.accessToken, "DELETE");
        assert.equal(denyOther.status, 404);
        assert.equal((await call(`/auth/devices/${target.id}`, undefined, source.accessToken, "DELETE")).status, 200);
        assert.equal((await call(`/auth/devices/${target.id}`, undefined, source.accessToken, "DELETE")).status, 200);
        assert.equal((await call("/auth/session", undefined, result.accessToken, "GET")).status, 401);
        assert.equal((await call("/dashboard", undefined, result.accessToken, "GET")).status, 401);
        const targetCookie = consumed.headers.get("set-cookie")!.split(";")[0];
        assert.equal((await call("/auth/refresh", undefined, undefined, "POST", targetCookie)).status, 401);
        assert.equal((await deviceService.list(sourceAuth)).activeCount, 1);
      });

      await t.test("expiry, denial, cancellation and code/id mismatch cannot authenticate", async () => {
        const expired = await qrLoginService.create(deviceMetadata());
        await prisma.loginChallenge.update({ where: { id: expired.challengeId }, data: { expiresAt: new Date(Date.now() - 1) } });
        assert.equal((await qrLoginService.status(expired.challengeId, expired.pollToken)).status, "expired");
        await assert.rejects(qrLoginService.decide(sourceAuth, expired.challengeId, expired.code, "approve"), { code: "LOGIN_CHALLENGE_UNAVAILABLE" });
        const denied = await qrLoginService.create(deviceMetadata());
        await qrLoginService.decide(sourceAuth, denied.challengeId, denied.code, "deny");
        assert.equal((await qrLoginService.status(denied.challengeId, denied.pollToken)).status, "denied");
        await assert.rejects(qrLoginService.consume(denied.challengeId, denied.pollToken), { code: "LOGIN_CHALLENGE_UNAVAILABLE" });
        const cancelled = await qrLoginService.create(deviceMetadata());
        await assert.rejects(qrLoginService.decide(sourceAuth, cancelled.challengeId, expired.code, "approve"), { code: "LOGIN_CHALLENGE_UNAVAILABLE" });
        await qrLoginService.decide(sourceAuth, cancelled.challengeId, cancelled.code, "approve");
        await qrLoginService.cancel(cancelled.challengeId, cancelled.pollToken);
        await assert.rejects(qrLoginService.consume(cancelled.challengeId, cancelled.pollToken), { code: "LOGIN_CHALLENGE_UNAVAILABLE" });
        const approvedExpired = await qrLoginService.create(deviceMetadata());
        await qrLoginService.decide(sourceAuth, approvedExpired.challengeId, approvedExpired.code, "approve");
        await prisma.loginChallenge.update({ where: { id: approvedExpired.challengeId }, data: { expiresAt: new Date(Date.now() - 1) } });
        await assert.rejects(qrLoginService.consume(approvedExpired.challengeId, approvedExpired.pollToken), { code: "LOGIN_CHALLENGE_UNAVAILABLE" });
      });

      await t.test("competing approvals and claims have exactly one winner", async () => {
        const challenge = await qrLoginService.create(deviceMetadata());
        const approvals = await Promise.allSettled([
          qrLoginService.decide(sourceAuth, challenge.challengeId, challenge.code, "approve"),
          qrLoginService.decide(verifyAccessToken(other.accessToken), challenge.challengeId, challenge.code, "approve"),
        ]);
        assert.equal(approvals.filter((result) => result.status === "fulfilled").length, 1);
        const before = await prisma.deviceSession.count();
        const claims = await Promise.allSettled([
          qrLoginService.consume(challenge.challengeId, challenge.pollToken),
          qrLoginService.consume(challenge.challengeId, challenge.pollToken),
        ]);
        assert.equal(claims.filter((result) => result.status === "fulfilled").length, 1);
        assert.equal(await prisma.deviceSession.count(), before + 1);
        const stored = await prisma.loginChallenge.findUniqueOrThrow({ where: { id: challenge.challengeId } });
        for (const result of claims) {
          if (result.status === "fulfilled") assert.equal(result.value.user.id, stored.approvedByUserId);
          else assert.equal(z.object({ code: z.string() }).parse(result.reason).code, "LOGIN_CHALLENGE_UNAVAILABLE");
        }
      });

      await t.test("rotation preserves the device; reused refresh tokens revoke all access", async () => {
        const session = await prisma.$transaction((tx) => issueSession(tx, user, deviceMetadata()));
        const auth = verifyAccessToken(session.accessToken);
        const before = await prisma.deviceSession.findUniqueOrThrow({ where: { id: auth.deviceId } });
        const rotated = await authService.refresh(session.refreshToken);
        assert.equal(verifyAccessToken(rotated.tokens.accessToken).deviceId, auth.deviceId);
        const after = await prisma.deviceSession.findUniqueOrThrow({ where: { id: auth.deviceId } });
        assert.equal(after.createdAt.getTime(), before.createdAt.getTime());
        await assert.rejects(authService.refresh(session.refreshToken), { code: "SESSION_REUSE_DETECTED" });
        await assert.rejects(assertActiveDevice(verifyAccessToken(rotated.tokens.accessToken)), { code: "SESSION_EXPIRED" });
        await assert.rejects(authService.refresh(rotated.tokens.refreshToken), { code: "SESSION_EXPIRED" });
        const concurrent = await prisma.$transaction((tx) => issueSession(tx, user, deviceMetadata()));
        const attempts = await Promise.allSettled([authService.refresh(concurrent.refreshToken), authService.refresh(concurrent.refreshToken)]);
        assert.equal(attempts.filter((result) => result.status === "fulfilled").length, 1);
        const concurrentAuth = verifyAccessToken(concurrent.accessToken);
        await assert.rejects(assertActiveDevice(concurrentAuth), { code: "SESSION_EXPIRED" });
      });

      await t.test("expired sessions are excluded from device counts and cannot authenticate", async () => {
        const session = await prisma.$transaction((tx) => issueSession(tx, user, deviceMetadata()));
        const deviceId = verifyAccessToken(session.accessToken).deviceId!;
        await prisma.deviceSession.update({ where: { id: deviceId }, data: { expiresAt: new Date(Date.now() - 1000) } });
        const listed = await deviceService.list(sourceAuth);
        assert.equal(listed.activeCount, listed.devices.length);
        assert.equal(listed.devices.some((device) => device.id === deviceId), false);
        assert.equal((await call("/dashboard", undefined, session.accessToken, "GET")).status, 401);
        await assert.rejects(authService.refresh(session.refreshToken), { code: "SESSION_EXPIRED" });
      });

      await t.test("revoked approvers and disabled accounts cannot grant or claim login", async () => {
        const temp = await prisma.$transaction((tx) => issueSession(tx, user, deviceMetadata()));
        const tempAuth = verifyAccessToken(temp.accessToken);
        const challenge = await qrLoginService.create(deviceMetadata());
        await qrLoginService.decide(tempAuth, challenge.challengeId, challenge.code, "approve");
        await deviceService.revoke(sourceAuth, tempAuth.deviceId!);
        await assert.rejects(qrLoginService.consume(challenge.challengeId, challenge.pollToken), { code: "SESSION_EXPIRED" });
        await assert.rejects(qrLoginService.decide(tempAuth, challenge.challengeId, challenge.code, "approve"), { code: "SESSION_EXPIRED" });
        const disabled = await qrLoginService.create(deviceMetadata());
        await qrLoginService.decide(sourceAuth, disabled.challengeId, disabled.code, "approve");
        await prisma.user.update({ where: { id: user.id }, data: { status: "DISABLED" } });
        assert.equal((await call("/auth/session", undefined, source.accessToken, "GET")).status, 401);
        await assert.rejects(authService.refresh(source.refreshToken), { code: "ACCOUNT_DISABLED" });
        await assert.rejects(qrLoginService.consume(disabled.challengeId, disabled.pollToken), { code: "ACCOUNT_DISABLED" });
        await prisma.user.update({ where: { id: user.id }, data: { status: "ACTIVE" } });
      });

      await t.test("activity updates are throttled; current-device logout invalidates access", async () => {
        const deviceId = sourceAuth.deviceId!;
        await prisma.deviceSession.update({ where: { id: deviceId }, data: { lastUsedAt: new Date(Date.now() - 120000) } });
        assert.equal((await call("/auth/devices", undefined, source.accessToken, "GET")).status, 200);
        const used = await prisma.deviceSession.findUniqueOrThrow({ where: { id: deviceId } });
        assert.ok(Date.now() - used.lastUsedAt.getTime() < 5000);
        await call("/auth/session", undefined, source.accessToken, "GET");
        assert.equal((await prisma.deviceSession.findUniqueOrThrow({ where: { id: deviceId } })).lastUsedAt.getTime(), used.lastUsedAt.getTime());
        const logout = await call(`/auth/devices/${deviceId}`, undefined, source.accessToken, "DELETE");
        assert.equal((await readData(logout, z.object({ deviceId: z.string(), isCurrent: z.boolean() }))).isCurrent, true);
        assert.match(logout.headers.get("set-cookie") ?? "", /Expires=/);
        assert.equal((await call("/auth/session", undefined, source.accessToken, "GET")).status, 401);
        await authService.logout(other.refreshToken);
        assert.equal((await call("/auth/session", undefined, other.accessToken, "GET")).status, 401);
      });

      await t.test("origin, validation and request quotas enforce the HTTP boundary", async () => {
        const crossSite = await fetch(`${base}/auth/logout`, { method: "POST", headers: { origin: "https://untrusted.example" } });
        assert.equal(crossSite.status, 403);
        assert.equal((await call("/auth/qr/challenges", { userId: user.id })).status, 400);
        let limited: Response | undefined;
        let allowed = 0;
        for (let attempt = 0; attempt < 12; attempt += 1) {
          const response = await call("/auth/qr/challenges", {});
          if (response.status === 429) { limited = response; break; }
          assert.equal(response.status, 201);
          allowed += 1;
        }
        assert.ok(limited);
        assert.equal(allowed, 8, "Ten create attempts include the previous valid and invalid requests");
        assert.equal(limited.headers.get("ratelimit-limit"), "10");
        assert.equal(limited.headers.get("cache-control"), "no-store");
        assert.equal(await readErrorCode(limited), "RATE_LIMITED");
        const quotaSession = await prisma.$transaction((tx) => issueSession(tx, user, deviceMetadata()));
        for (let attempt = 0; attempt < 18; attempt += 1) {
          assert.equal((await call("/auth/qr/lookup", { code: "9999999999" }, quotaSession.accessToken)).status, 404);
        }
        const lookupLimited = await call("/auth/qr/lookup", { code: "9999999999" }, quotaSession.accessToken);
        assert.equal(lookupLimited.status, 429);
        assert.equal(lookupLimited.headers.get("ratelimit-limit"), "20");
        assert.equal(await readErrorCode(lookupLimited), "RATE_LIMITED");
        const pollChallenge = await qrLoginService.create(deviceMetadata());
        for (let attempt = 0; attempt < 28; attempt += 1) {
          assert.equal((await call(`/auth/qr/challenges/${pollChallenge.challengeId}/status`, { pollToken: pollChallenge.pollToken })).status, 200);
        }
        const pollLimited = await call(`/auth/qr/challenges/${pollChallenge.challengeId}/status`, { pollToken: pollChallenge.pollToken });
        assert.equal(pollLimited.status, 429);
        assert.equal(pollLimited.headers.get("ratelimit-limit"), "30");
        assert.equal(await readErrorCode(pollLimited), "RATE_LIMITED");
        const malformed = await fetch(`${base}/auth/qr/challenges`, {
          method: "POST", headers: { "content-type": "application/json" }, body: "{",
        });
        assert.equal(malformed.status, 400);
        assert.equal(malformed.headers.get("cache-control"), "no-store");
      });

      await t.test("retention cleanup deletes old requests without removing live requests", async () => {
        const { cleanupLoginChallenges } = await import("../src/features/auth/auth_cleanup.js");
        const old = await qrLoginService.create(deviceMetadata());
        await prisma.loginChallenge.update({ where: { id: old.challengeId }, data: { expiresAt: new Date(Date.now() - 2 * 86400000) } });
        const live = await qrLoginService.create(deviceMetadata());
        assert.equal(await cleanupLoginChallenges(), 1);
        assert.equal(await prisma.loginChallenge.findUnique({ where: { id: old.challengeId } }), null);
        assert.equal((await qrLoginService.status(live.challengeId, live.pollToken)).status, "pending");
      });
    } finally {
      await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    }
  } finally {
    await db?.$disconnect();
    if (databaseCreated) await admin.$executeRawUnsafe(`DROP DATABASE \`${databaseName}\``);
    await admin.$disconnect();
    await rm(temporary, { recursive: true });
  }
});
