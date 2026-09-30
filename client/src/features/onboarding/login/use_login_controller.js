import { useEffect, useState } from "react";
import { getApiErrorMessage, refreshSession, setAccessToken, setSessionExpiredHandler } from "@/services/api_client.js";
import { getSession, loginWithGoogleCredential, logoutSession } from "./login_repository.js";

export function useLoginController() {
  const [user, setUser] = useState(null);
  const [isBootstrapping, setIsBootstrapping] = useState(true);
  const [isAuthenticating, setIsAuthenticating] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [error, setError] = useState("");
  const [path, setPath] = useState(window.location.pathname);

  function navigate(nextPath) {
    window.history.replaceState(null, "", nextPath);
    setPath(nextPath);
  }

  useEffect(() => {
    let mounted = true;
    setSessionExpiredHandler(() => {
      setAccessToken(null);
      setUser(null);
      navigate("/login");
    });
    const handlePopState = () => setPath(window.location.pathname);
    window.addEventListener("popstate", handlePopState);

    async function bootstrap() {
      try {
        await refreshSession();
        const session = await getSession();
        if (mounted) {
          setUser(session);
          navigate("/");
        }
      } catch {
        setAccessToken(null);
        if (mounted) navigate("/login");
      } finally {
        if (mounted) setIsBootstrapping(false);
      }
    }

    void bootstrap();
    return () => {
      mounted = false;
      setSessionExpiredHandler(() => {});
      window.removeEventListener("popstate", handlePopState);
    };
  }, []);

  async function login(credential) {
    if (!credential) {
      setError("Google did not return a credential. Please try again.");
      return;
    }
    setIsAuthenticating(true);
    setError("");
    try {
      const result = await loginWithGoogleCredential(credential);
      setAccessToken(result.accessToken);
      setUser(await getSession());
      navigate("/");
    } catch (requestError) {
      setAccessToken(null);
      setError(getApiErrorMessage(requestError));
    } finally {
      setIsAuthenticating(false);
    }
  }

  async function logout() {
    setIsLoggingOut(true);
    try {
      await logoutSession();
    } catch (requestError) {
      setError(getApiErrorMessage(requestError));
    } finally {
      setAccessToken(null);
      setUser(null);
      setIsLoggingOut(false);
      navigate("/login");
    }
  }

  return {
    user, isBootstrapping, isAuthenticating, isLoggingOut, error, setError, login, logout, path,
    onPreferenceUpdated: (preference) => setUser((current) => current ? { ...current, preference } : current),
  };
}