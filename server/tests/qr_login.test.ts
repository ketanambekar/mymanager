import assert from "node:assert/strict";
import test from "node:test";
import type { LoginChallenge } from "@prisma/client";

process.env.DATABASE_URL ??= "mysql://test:test@localhost:3306/test";
process.env.GOOGLE_CLIENT_ID ??= "test.apps.googleusercontent.com";
process.env.JWT_ACCESS_SECRET ??= "test-secret-at-least-thirty-two-characters";

test("QR request status respects expiry and terminal states", async () => {
  const { challengeStatus, challengeLifetimeMs } = await import("../src/features/auth/qr_login_service.js");
  const now = new Date();
  const challenge: LoginChallenge = {
    id: "id", codeHash: "hash", pollTokenHash: "hash", deviceName: "browser", userAgent: null,
    createdAt: now, expiresAt: new Date(now.getTime() + challengeLifetimeMs),
    approvedByUserId: null, approvedDeviceId: null, approvedAt: null, deniedAt: null, consumedAt: null,
  };
  assert.equal(challengeLifetimeMs, 300000);
  assert.equal(challengeStatus(challenge, now), "pending");
  assert.equal(challengeStatus({ ...challenge, approvedAt: now }, now), "approved");
  assert.equal(challengeStatus({ ...challenge, approvedAt: now, expiresAt: now }, now), "expired");
  assert.equal(challengeStatus({ ...challenge, deniedAt: now }, now), "denied");
  assert.equal(challengeStatus({ ...challenge, consumedAt: now }, now), "consumed");
});

test("QR boundaries reject malformed inputs and unexpected fields", async () => {
  const schemas = await import("../src/features/auth/auth_schema.js");
  assert.equal(schemas.loginCodeSchema.safeParse({ code: "0012345678" }).success, true);
  for (const code of ["1234", 1234567890, "123456789a", "12345678901"]) {
    assert.equal(schemas.loginCodeSchema.safeParse({ code }).success, false);
  }
  assert.equal(schemas.challengeSecretSchema.safeParse({ pollToken: "x".repeat(64) }).success, true);
  assert.equal(schemas.challengeSecretSchema.safeParse({ pollToken: "x".repeat(63) }).success, false);
  assert.equal(schemas.createChallengeSchema.safeParse({ deviceName: " " }).success, false);
  assert.equal(schemas.createChallengeSchema.safeParse({ userId: 1 }).success, false);
  assert.equal(schemas.decideChallengeSchema.safeParse({ code: "1234567890", decision: "approve", userId: 1 }).success, false);
});

test("device metadata is bounded and access tokens retain device binding", async () => {
  const { deviceMetadata } = await import("../src/features/auth/device_service.js");
  const { signAccessToken, verifyAccessToken } = await import("../src/features/auth/auth_token.js");
  assert.equal(deviceMetadata("Mozilla Windows Chrome/1").deviceName, "Chrome on Windows");
  assert.equal(deviceMetadata("x".repeat(1000)).userAgent?.length, 512);
  const payload = { sub: 1, email: "test@example.com", displayName: "Test", workspaceId: 1, deviceId: "device-id" };
  assert.deepEqual(verifyAccessToken(signAccessToken(payload)), payload);
});
