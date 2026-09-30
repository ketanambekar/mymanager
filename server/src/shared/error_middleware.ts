import type { ErrorRequestHandler } from "express";
import { Prisma } from "@prisma/client";
import { ZodError } from "zod";
import { AppError } from "./app_error.js";

export const errorMiddleware: ErrorRequestHandler = (error, request, response, _next) => {
  if (error instanceof SyntaxError && "body" in error) {
    response.status(400).json({ success: false, error: { code: "MALFORMED_JSON", message: "Request body must contain valid JSON", requestId: request.requestId } });
    return;
  }

  if (error instanceof ZodError) {
    response.status(400).json({ success: false, error: { code: "VALIDATION_ERROR", message: "Validation failed", details: error.issues, requestId: request.requestId } });
    return;
  }

  if (error instanceof AppError) {
    response.status(error.statusCode).json({ success: false, error: { code: error.code, message: error.message, details: error.details, requestId: request.requestId } });
    return;
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
    response.status(409).json({ success: false, error: { code: "CONFLICT", message: "A record with this value already exists", requestId: request.requestId } });
    return;
  }

  console.error(`[${request.requestId}] Unhandled error`, error);
  response.status(500).json({ success: false, error: { code: "INTERNAL_ERROR", message: "Internal server error", requestId: request.requestId } });
};