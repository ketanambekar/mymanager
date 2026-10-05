import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

const sourceDirectory = fileURLToPath(new URL("./src", import.meta.url));
const { version } = JSON.parse(
  readFileSync(new URL("./package.json", import.meta.url), "utf8"),
);

export default defineConfig(({ mode }) => {
  // Dev-only: proxy /api to a remote API so the browser sees same-origin requests (no CORS, first-party refresh cookie).
  const { API_PROXY_TARGET } = loadEnv(mode, process.cwd(), "API_");

  return {
    plugins: [react()],
    resolve: {
      alias: {
        "@": sourceDirectory,
      },
    },
    define: {
      __APP_VERSION__: JSON.stringify(version),
    },
    server: API_PROXY_TARGET
      ? { proxy: { "/api": { target: API_PROXY_TARGET, changeOrigin: true, secure: true } } }
      : undefined,
  };
});