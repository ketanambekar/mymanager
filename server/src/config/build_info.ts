import packageJson from "../../package.json";

const commit = process.env.GIT_COMMIT?.trim();

export const buildInfo = Object.freeze({
  version: packageJson.version,
  commit: commit && /^[0-9a-f]{7,40}$/i.test(commit) ? commit.slice(0, 12) : "unknown",
  builtAt: process.env.BUILD_TIME?.trim() || null,
});
