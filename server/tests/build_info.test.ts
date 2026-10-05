import assert from "node:assert/strict";
import { once } from "node:events";
import test from "node:test";
import packageJson from "../package.json";

process.env.DATABASE_URL ??= "mysql://user:password@localhost:3306/test";
process.env.GOOGLE_CLIENT_ID ??= "test.apps.googleusercontent.com";
process.env.JWT_ACCESS_SECRET ??= "test-secret-at-least-thirty-two-characters";
process.env.GIT_COMMIT = "0123456789abcdef0123456789abcdef01234567";
process.env.BUILD_TIME = "2026-10-05T13:45:00Z";

test("health and response headers report the running release", async () => {
  const { version } = packageJson;
  const { app } = await import("../src/app.js");
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");

  try {
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("Expected a TCP listener");
    const response = await fetch(`http://127.0.0.1:${address.port}/health`);
    const body = await response.json() as { data: unknown };

    assert.equal(response.status, 200);
    assert.equal(response.headers.get("x-api-version"), version);
    assert.deepEqual(body.data, { status: "ok", version, commit: "0123456789ab", builtAt: "2026-10-05T13:45:00Z" });
  } finally {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});
