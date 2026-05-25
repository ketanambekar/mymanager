import { z } from "zod";
import { loginWithGoogleSchema } from "./auth.validation";

export type LoginWithGoogleDto = z.infer<typeof loginWithGoogleSchema.shape.body>;

export type AuthTokens = {
  accessToken: string;
  refreshToken: string;
  accessTokenExpiresIn: string;
};
