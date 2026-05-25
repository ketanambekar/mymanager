import { create } from "zustand";
import { fetchJson, setAccessToken, setRefreshHandler } from "@/lib/api";
import { AuthMeResponse, AuthTokenResponse, AuthUser } from "@/types/auth";

type AuthState = {
  user: AuthUser | null;
  accessToken: string | null;
  isBootstrapping: boolean;
  isAuthenticating: boolean;
  initialized: boolean;
  bootstrap: () => Promise<void>;
  loginWithGoogleCredential: (credential: string) => Promise<void>;
  refreshAccessToken: () => Promise<string | null>;
  logout: () => Promise<void>;
};

async function postAuthToken(path: string, body?: Record<string, unknown>): Promise<AuthTokenResponse> {
  return fetchJson<AuthTokenResponse>({
    path,
    method: "POST",
    body: body ? JSON.stringify(body) : undefined,
    skipAuthRetry: true,
  });
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  accessToken: null,
  isBootstrapping: false,
  isAuthenticating: false,
  initialized: false,

  refreshAccessToken: async () => {
    try {
      const response = await postAuthToken("/auth/refresh");
      const token = response.data.accessToken;
      set({ accessToken: token, user: response.data.user });
      setAccessToken(token);
      return token;
    } catch {
      set({ accessToken: null, user: null });
      setAccessToken(null);
      return null;
    }
  },

  bootstrap: async () => {
    if (get().isBootstrapping || get().initialized) {
      return;
    }

    set({ isBootstrapping: true });

    try {
      const token = await get().refreshAccessToken();
      if (token) {
        const me = await fetchJson<AuthMeResponse>({ path: "/auth/me", skipAuthRetry: true });
        set({ user: me.data });
      }
    } finally {
      set({ isBootstrapping: false, initialized: true });
    }
  },

  loginWithGoogleCredential: async (credential: string) => {
    set({ isAuthenticating: true });

    try {
      const response = await postAuthToken("/auth/google", { credential });
      set({
        user: response.data.user,
        accessToken: response.data.accessToken,
      });
      setAccessToken(response.data.accessToken);
    } finally {
      set({ isAuthenticating: false });
    }
  },

  logout: async () => {
    try {
      await fetchJson<{ success: true; message: string }>({
        path: "/auth/logout",
        method: "POST",
        skipAuthRetry: true,
      });
    } finally {
      set({ user: null, accessToken: null });
      setAccessToken(null);
    }
  },
}));

setRefreshHandler(async () => useAuthStore.getState().refreshAccessToken());
