import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

if (!process.env.DATABASE_URL && process.env.MYSQL_URL) {
  process.env.DATABASE_URL = process.env.MYSQL_URL;
}

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  HOST: z.string().default("0.0.0.0"),
  PORT: z.coerce.number().int().min(1).max(65535).default(5000),
  DATABASE_URL: z.string().min(1),
  FRONTEND_URL: z.string().min(1).default("http://localhost:5173"),
  GOOGLE_CLIENT_ID: z.string().min(1),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRES_IN: z.string().default("15m"),
  REFRESH_TOKEN_EXPIRES_DAYS: z.coerce.number().int().min(1).max(90).default(14),
  REFRESH_TOKEN_COOKIE_NAME: z.string().default("mm_refresh_token"),
});

export const env = schema.parse(process.env);
export const frontendOrigins = env.FRONTEND_URL.split(",").map((origin) => origin.trim()).filter(Boolean);