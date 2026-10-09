import { useEffect, useRef, useState } from "react";
import { getApiErrorMessage, refreshSession, setAccessToken, setSessionExpiredHandler } from "@/services/api_client.js";
import {
  cancelQrChallenge,
  consumeQrChallenge,
  createQrChallenge,
  getQrChallengeStatus,
  getSession,
  loginWithGoogleCredential,
  logoutSession,
} from "./login_repository.js";

export function useLoginController() {
  const [user, setUser] = useState(null);
  const [isBootstrapping, setIsBootstrapping] = useState(true);
  const [isAuthenticating, setIsAuthenticating] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [error, setError] = useState("");
  const [path, setPath] = useState(window.location.pathname);
  const [qrStatus, setQrStatus] = useState("idle");
  const [qrRequest, setQrRequest] = useState(null);
  const [qrError, setQrError] = useState("");
  const [clock, setClock] = useState(() => Date.now());
  const qrRequestRef = useRef(null);
  const qrGenerationRef = useRef(0);
  const consumedChallengeRef = useRef(null);
  const creatingQrRef = useRef(false);
  const cancellingQrRef = useRef(false);

  function navigate(nextPath) {
    window.history.replaceState(null, "", nextPath);
    setPath(nextPath);
  }

  function clearQrRequest() {
    qrRequestRef.current = null;
    setQrRequest(null);
  }

  async function cancelRequest(request) {
    await cancelQrChallenge(request.challengeId, request.pollToken);
  }

  async function createQrLoginRequest() {
    const generation = ++qrGenerationRef.current;
    const previousRequest = qrRequestRef.current;
    setQrError("");
    setQrStatus("creating");

    if (previousRequest) {
      try {
        await cancelRequest(previousRequest);
      } catch (requestError) {
        setQrStatus("error");
        setQrError(`The previous sign-in request could not be cancelled: ${getApiErrorMessage(requestError)}`);
        return;
      }
      if (generation !== qrGenerationRef.current) return;
      clearQrRequest();
    }

    try {
      const request = await createQrChallenge();
      if (generation !== qrGenerationRef.current) {
        try {
          await cancelRequest(request);
        } catch (requestError) {
          setQrError(`The unused sign-in request could not be cancelled: ${getApiErrorMessage(requestError)}`);
        }
        return;
      }
      qrRequestRef.current = request;
      setQrRequest(request);
      setQrStatus("waiting");
    } catch (requestError) {
      if (generation !== qrGenerationRef.current) return;
      setQrStatus("error");
      setQrError(getApiErrorMessage(requestError));
    }
  }

  async function startQrLogin() {
    if (creatingQrRef.current) return;
    creatingQrRef.current = true;
    try {
      await createQrLoginRequest();
    } finally {
      creatingQrRef.current = false;
    }
  }

  async function cancelQrLogin() {
    if (cancellingQrRef.current) return;
    const request = qrRequestRef.current;
    if (!request) {
      setQrStatus("cancelled");
      return;
    }
    cancellingQrRef.current = true;
    ++qrGenerationRef.current;
    setQrStatus("cancelling");
    setQrError("");
    try {
      await cancelRequest(request);
      clearQrRequest();
      setQrStatus("cancelled");
    } catch (requestError) {
      setQrStatus("error");
      setQrError(`The sign-in request could not be cancelled: ${getApiErrorMessage(requestError)}`);
    } finally {
      cancellingQrRef.current = false;
    }
  }

  async function claimQrLogin(request, generation) {
    if (consumedChallengeRef.current === request.challengeId) return;
    consumedChallengeRef.current = request.challengeId;
    setQrStatus("claiming");
    try {
      const result = await consumeQrChallenge(request.challengeId, request.pollToken);
      if (generation !== qrGenerationRef.current) return;
      setAccessToken(result.accessToken);
      const session = await getSession();
      if (generation !== qrGenerationRef.current) return;
      clearQrRequest();
      setUser(session);
      setQrStatus("authenticated");
      navigate("/");
    } catch (requestError) {
      if (generation !== qrGenerationRef.current) return;
      if (!requestError.response) {
        try {
          await refreshSession();
          const session = await getSession();
          if (generation !== qrGenerationRef.current) return;
          clearQrRequest();
          setUser(session);
          setQrStatus("authenticated");
          navigate("/");
          return;
        } catch {
          setAccessToken(null);
        }
      }
      setAccessToken(null);
      setQrStatus("error");
      setQrError(getApiErrorMessage(requestError));
    }
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

  useEffect(() => {
    const intervalId = window.setInterval(() => setClock(Date.now()), 1000);
    return () => window.clearInterval(intervalId);
  }, []);

  useEffect(() => {
    if (path === "/login" || !qrRequestRef.current) return;
    const request = qrRequestRef.current;
    ++qrGenerationRef.current;
    clearQrRequest();
    setQrStatus("cancelled");
    cancelRequest(request).catch((requestError) => {
      setQrStatus("error");
      setQrError(`The sign-in request could not be cancelled after leaving the login page: ${getApiErrorMessage(requestError)}`);
    });
  }, [path]);

  useEffect(() => {
    if (!qrRequest || qrStatus !== "waiting" || path !== "/login") return undefined;
    let active = true;
    let timeoutId;
    const generation = qrGenerationRef.current;
    const intervalMs = Math.max(1, qrRequest.pollIntervalSeconds) * 1000;

    async function poll() {
      if (!active) return;
      try {
        const result = await getQrChallengeStatus(qrRequest.challengeId, qrRequest.pollToken);
        if (!active || generation !== qrGenerationRef.current) return;
        if (result.status === "pending") {
          timeoutId = window.setTimeout(poll, intervalMs);
        } else if (result.status === "approved") {
          await claimQrLogin(qrRequest, generation);
        } else {
          clearQrRequest();
          setQrStatus(result.status === "denied" ? "denied" : "expired");
        }
      } catch (requestError) {
        if (!active || generation !== qrGenerationRef.current) return;
        setQrError(getApiErrorMessage(requestError));
        setQrStatus("error");
      }
    }

    timeoutId = window.setTimeout(poll, intervalMs);
    return () => {
      active = false;
      window.clearTimeout(timeoutId);
    };
  }, [path, qrRequest, qrStatus]);

  useEffect(() => {
    if (!qrRequest || !["waiting", "error"].includes(qrStatus)) return undefined;
    const timeoutId = window.setTimeout(() => {
      if (Date.parse(qrRequest.expiresAt) <= Date.now()) {
        ++qrGenerationRef.current;
        clearQrRequest();
        setQrStatus("expired");
      }
    }, Math.max(0, Date.parse(qrRequest.expiresAt) - clock));
    return () => window.clearTimeout(timeoutId);
  }, [clock, qrRequest, qrStatus]);

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
    ++qrGenerationRef.current;
    clearQrRequest();
    setQrStatus("idle");
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

  function retryQrLogin() {
    if (qrRequestRef.current) {
      setQrError("");
      setQrStatus("waiting");
    } else {
      void startQrLogin();
    }
  }

  function clearSession() {
    ++qrGenerationRef.current;
    clearQrRequest();
    setAccessToken(null);
    setUser(null);
    navigate("/login");
  }

  return {
    user, isBootstrapping, isAuthenticating, isLoggingOut, error, setError, login, logout, path,
    navigate, clearSession, qrStatus, qrRequest, qrError, startQrLogin, cancelQrLogin,
    retryQrLogin,
    qrSecondsRemaining: qrRequest ? Math.max(0, Math.ceil((Date.parse(qrRequest.expiresAt) - clock) / 1000)) : 0,
    onPreferenceUpdated: (preference) => setUser((current) => current ? { ...current, preference } : current),
  };
}