export type AuthUser = {
  id: number;
  email: string;
  name: string;
  avatarUrl?: string | null;
  provider: "GOOGLE";
  authProvider?: "GOOGLE";
  emailVerifiedAt?: string | null;
  createdAt?: string;
  updatedAt?: string;
  lastLoginAt?: string | null;
  isActive?: boolean;
};

type AuthEnvelope = {
  success: true;
  data: {
    user: AuthUser;
    accessToken: string;
    accessTokenExpiresIn: string;
  };
};

export type AuthTokenResponse = AuthEnvelope;

export type AuthMeResponse = {
  success: true;
  data: AuthUser;
};
