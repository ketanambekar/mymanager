import "../config/env.js";
import { prisma } from "../database/prisma.js";
import { cleanupLoginChallenges } from "../features/auth/auth_cleanup.js";

async function main() {
  try {
    console.log(`Deleted ${await cleanupLoginChallenges()} expired login challenges`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error: unknown) => {
  console.error("Authentication cleanup failed", error);
  process.exitCode = 1;
});
