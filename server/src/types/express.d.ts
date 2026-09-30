import type { AccessTokenPayload } from "../features/auth/auth_token.js";

declare global {
  namespace Express {
    interface Request {
      auth: AccessTokenPayload | null;
      validatedBody?: unknown;
      validatedParams?: unknown;
      validatedQuery?: unknown;
      requestId: string;
    }
  }
}

export {};