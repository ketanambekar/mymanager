import { PrismaClient } from "@prisma/client";

if (!process.env.DATABASE_URL && process.env.MYSQL_URL) {
	process.env.DATABASE_URL = process.env.MYSQL_URL;
}

export const prisma = new PrismaClient();
