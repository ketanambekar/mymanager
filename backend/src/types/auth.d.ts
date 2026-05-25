export type AuthUser = {
  id: number;
  email: string;
  name: string;
  avatarUrl?: string | null;
  provider: "GOOGLE";
};

export type AuthContext = {
  user: AuthUser;
  accessToken: string;
};

declare global {
  namespace Express {
    interface Request {
      auth?: AuthContext | null;
    }
  }
}