import { prisma } from "../../database/prisma.js";

export async function cleanupLoginChallenges(now = new Date()) {
  const cutoff = new Date(now.getTime() - 86400000);
  let deleted = 0;
  while (true) {
    const batch = await prisma.loginChallenge.findMany({
      where: { expiresAt: { lt: cutoff } }, select: { id: true }, take: 1000,
    });
    if (!batch.length) return deleted;
    const result = await prisma.loginChallenge.deleteMany({
      where: { id: { in: batch.map((challenge) => challenge.id) }, expiresAt: { lt: cutoff } },
    });
    deleted += result.count;
  }
}
