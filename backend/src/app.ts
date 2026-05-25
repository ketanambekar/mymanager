import cookieParser from "cookie-parser";
import cors from "cors";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import morgan from "morgan";
import { env } from "./config/env";
import { attachAuthContext } from "./middlewares/authContext";
import { errorMiddleware } from "./middlewares/errorMiddleware";
import { apiRouter } from "./routes";

export const app = express();

const allowedOrigins = env.FRONTEND_URL.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

const allowedOriginHosts = allowedOrigins
  .map((origin) => {
    try {
      return new URL(origin).hostname;
    } catch {
      return null;
    }
  })
  .filter((hostname): hostname is string => Boolean(hostname));

function isOriginAllowed(origin: string): boolean {
  if (allowedOrigins.includes(origin)) {
    return true;
  }

  if (env.NODE_ENV !== "development") {
    return false;
  }

  try {
    const parsedOrigin = new URL(origin);
    return allowedOriginHosts.includes(parsedOrigin.hostname);
  } catch {
    return false;
  }
}

app.use(helmet());
app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || isOriginAllowed(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error("Origin not allowed by CORS"));
    },
    credentials: true,
  }),
);
app.use(morgan("dev"));
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 300,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);
app.use(express.json());
app.use(cookieParser());
app.use(attachAuthContext);

app.get("/health", (_req, res) => {
  res.status(200).json({ success: true, message: "Backend is running" });
});

app.use("/api/v1", apiRouter);
app.use(errorMiddleware);
