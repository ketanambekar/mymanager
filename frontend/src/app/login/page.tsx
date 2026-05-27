"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { CredentialResponse, GoogleLogin, GoogleOAuthProvider } from "@react-oauth/google";
import { useAuthStore } from "@/store/auth-store";

const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";
const hasValidClientId = Boolean(clientId) && !clientId.includes("your-google-client-id");

export default function LoginPage() {
  const router = useRouter();
  const loginWithGoogleCredential = useAuthStore((state) => state.loginWithGoogleCredential);
  const isAuthenticating = useAuthStore((state) => state.isAuthenticating);
  const [loginError, setLoginError] = useState<string | null>(null);

  const loginDisabled = useMemo(() => isAuthenticating || !hasValidClientId, [isAuthenticating, hasValidClientId]);

  async function handleSuccess(response: CredentialResponse) {
    if (!response.credential) {
      setLoginError("Google did not return a credential. Please try again.");
      return;
    }

    setLoginError(null);

    try {
      await loginWithGoogleCredential(response.credential);
      router.replace("/");
    } catch (error) {
      setLoginError(error instanceof Error ? error.message : "Google sign-in failed. Please try again.");
    }
  }

  return (
    <main className="grain-layer relative min-h-screen overflow-hidden bg-[radial-gradient(circle_at_top_left,rgba(16,185,129,0.12),transparent_42%),radial-gradient(circle_at_80%_10%,rgba(245,158,11,0.14),transparent_38%),var(--paper)] px-4 py-8 text-[var(--ink)]">
      <header className="mx-auto mb-4 flex w-full max-w-6xl items-center rounded-2xl border border-[var(--border)] bg-[var(--paper-elevated)] px-4 py-3 sm:px-6">
        <div className="inline-flex items-center gap-2.5">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-full border border-orange-400/55 bg-gradient-to-br from-orange-400/30 to-emerald-400/20 text-[11px] font-black text-orange-100 shadow-[0_0_18px_rgba(249,115,22,0.35)]">
            M
          </span>
          <p className="bg-gradient-to-r from-orange-200 via-amber-100 to-emerald-200 bg-clip-text text-base font-black tracking-[0.08em] text-transparent [text-shadow:0_0_26px_rgba(249,115,22,0.2)] sm:text-lg">
            MyManager
          </p>
        </div>
      </header>

      <section className="mx-auto grid min-h-[calc(100vh-16rem)] w-full max-w-6xl grid-cols-1 items-start gap-6 lg:grid-cols-[minmax(0,1.15fr),minmax(0,0.85fr)]">
        <div className="space-y-5 rounded-3xl border border-[var(--border)] bg-[var(--paper-elevated)] p-6 shadow-[0_20px_60px_rgba(0,0,0,0.28)] sm:p-8">
          <p className="inline-flex rounded-full border border-[var(--border-strong)] bg-[var(--surface-muted)] px-3 py-1 text-xs font-semibold uppercase tracking-[0.12em] text-[var(--brand-ink)]">
            Smart Work Console
          </p>
          <h1 className="max-w-2xl text-4xl font-extrabold leading-tight text-[var(--ink)] sm:text-5xl">
            Plan projects, track tasks, and ship faster.
          </h1>
          <p className="max-w-2xl text-sm leading-7 text-[var(--muted)] sm:text-base">
            MyManager helps teams and individuals manage project pipelines, prioritize execution, and maintain progress with a
            clean dashboard and focused task queue.
          </p>

          <div className="grid gap-3 sm:grid-cols-3">
            <div className="rounded-2xl border border-emerald-400/35 bg-emerald-500/10 p-3">
              <p className="text-xl font-extrabold">Projects</p>
              <p className="text-xs text-[var(--muted)]">Organize type, color, and priority</p>
            </div>
            <div className="rounded-2xl border border-sky-400/35 bg-sky-500/10 p-3">
              <p className="text-xl font-extrabold">Tasks</p>
              <p className="text-xs text-[var(--muted)]">Status flow from pending to complete</p>
            </div>
            <div className="rounded-2xl border border-orange-400/35 bg-orange-500/10 p-3">
              <p className="text-xl font-extrabold">Masters</p>
              <p className="text-xs text-[var(--muted)]">Configure priorities, types, and colors</p>
            </div>
          </div>

          <div className="grid gap-3 rounded-2xl border border-[var(--border)] bg-[var(--surface-muted)] p-4">
            <p className="text-xs font-semibold uppercase tracking-[0.1em] text-[var(--muted)]">Why MyManager</p>
            <p className="text-sm leading-7 text-[var(--ink)]">
              Built for daily execution, MyManager combines project planning and task operations in one place so teams can reduce
              context switching and keep delivery predictable.
            </p>
            <div className="grid gap-1 text-xs text-[var(--muted)] sm:grid-cols-2">
              <p>• Focused task queue with clear status transitions</p>
              <p>• Project-first navigation and dedicated detail pages</p>
              <p>• Master data management for standardized workflows</p>
              <p>• Fast Google sign-in for secure access</p>
            </div>
          </div>
        </div>

        <div id="login-panel" className="rounded-3xl border border-[var(--border-strong)] bg-[linear-gradient(165deg,rgba(42,37,32,0.9),rgba(23,22,20,0.96))] p-6 shadow-[0_20px_60px_rgba(0,0,0,0.28)] sm:p-8">
          <h2 className="text-2xl font-bold text-[var(--ink)]">Login with Google</h2>
          <p className="mt-2 text-sm text-[var(--muted)]">Secure sign-in to access your projects and task dashboard.</p>

          <div className="mt-6 rounded-2xl border border-[var(--border)] bg-[var(--surface-muted)] p-4">
            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-[var(--ink)]">
              <span className="inline-flex h-6 w-6 items-center justify-center rounded-full border border-[var(--border)] bg-[var(--surface)] text-xs font-bold">
                G
              </span>
              <span>Sign in with Google</span>
            </div>

            <div className="min-h-12">
              {hasValidClientId ? (
                <GoogleOAuthProvider clientId={clientId}>
                  <div className="flex justify-start">
                    <GoogleLogin
                      onSuccess={handleSuccess}
                      onError={() => setLoginError("Google sign-in could not be initialized. Please refresh and try again.")}
                      useOneTap={false}
                      text="signin_with"
                      shape="pill"
                      size="large"
                      width="280"
                    />
                  </div>
                </GoogleOAuthProvider>
              ) : (
                <div className="rounded-xl border border-[var(--danger)]/70 bg-[#3f1f1b] p-3 text-xs text-[#ffb0a2]">
                  Missing NEXT_PUBLIC_GOOGLE_CLIENT_ID in frontend environment.
                </div>
              )}
            </div>
          </div>

          {loginError ? (
            <div className="mt-3 rounded-xl border border-[var(--danger)]/70 bg-[#3f1f1b] p-3 text-xs text-[#ffb0a2]">{loginError}</div>
          ) : null}

          {loginDisabled ? <p className="mt-3 text-xs text-[var(--muted)]">Preparing secure sign-in...</p> : null}
        </div>
      </section>

      <footer className="mx-auto mt-6 w-full max-w-6xl rounded-2xl border border-[var(--border)] bg-[var(--paper-elevated)] px-4 py-3 text-xs text-[var(--muted)] sm:px-6">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <p>MyManager. Plan clearly, execute consistently.</p>
          <a href="#login-panel" className="hover:text-[var(--ink)]">
            Login with Google
          </a>
        </div>
      </footer>
    </main>
  );
}
