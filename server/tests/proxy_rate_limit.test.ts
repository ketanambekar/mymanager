import assert from "node:assert/strict";
import { once } from "node:events";
import test from "node:test";

process.env.NODE_ENV = "production";
process.env.DATABASE_URL ??= "mysql://test:test@localhost:3306/test";
process.env.GOOGLE_CLIENT_ID ??= "test.apps.googleusercontent.com";
process.env.JWT_ACCESS_SECRET ??= "test-secret-at-least-thirty-two-characters";

test("production rate limits forwarded client IPs independently", async () => {
  const { app } = await import("../src/app.js");
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");

  try {
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("Expected a TCP listener");
    const url = `http://127.0.0.1:${address.port}/health`;
    const first = await fetch(url, { headers: { "x-forwarded-for": "198.51.100.10" } });
    const second = await fetch(url, { headers: { "x-forwarded-for": "203.0.113.20" } });
    const again = await fetch(url, { headers: { "x-forwarded-for": "198.51.100.10" } });

    assert.equal(first.status, 200);
    assert.equal(second.status, 200);
    assert.equal(first.headers.get("ratelimit-remaining"), second.headers.get("ratelimit-remaining"));
    assert.equal(Number(again.headers.get("ratelimit-remaining")), Number(first.headers.get("ratelimit-remaining")) - 1);
  } finally {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});

test("refresh exhaustion does not block Google login for the same client", async () => {
  const { app } = await import("../src/app.js");
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");

  try {
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("Expected a TCP listener");
    const base = `http://127.0.0.1:${address.port}/api/v1/auth`;
    const request = (path: string) => fetch(`${base}${path}`, {
      method: "POST",
      headers: { "x-forwarded-for": "192.0.2.45", "content-type": "application/json" },
      body: "{}",
    });

    for (let attempt = 0; attempt < 60; attempt += 1) {
      assert.equal((await request("/refresh")).status, 401);
    }
    assert.equal((await request("/refresh")).status, 429);
    const login = await request("/google");
    assert.equal(login.status, 400);
    assert.equal(Number(login.headers.get("ratelimit-remaining")), 29);
  } finally {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});