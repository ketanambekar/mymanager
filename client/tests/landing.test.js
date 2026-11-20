import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { createServer } from "vite";

test("the public landing page and login links are present in the initial HTML", async () => {
  const root = fileURLToPath(new URL("../", import.meta.url));
  const server = await createServer({ root, configFile: fileURLToPath(new URL("../vite.config.js", import.meta.url)), server: { middlewareMode: true } });
  try {
    const source = await readFile(new URL("../index.html", import.meta.url), "utf8");
    const html = await server.transformIndexHtml("/", source);
    assert.match(html, /<h1>Make room for <em>better work\.<\/em><\/h1>/);
    assert.match(html, /Bring your tasks together/);
    assert.match(html, /Make repeat work easier/);
    assert.match(html, /Give every project a place/);
    assert.match(html, /href="\/login"[^>]*>Get started with Google/);
    assert.match(html, /A product by <strong>KRD Labs<\/strong>/);
  } finally {
    await server.close();
  }
});
