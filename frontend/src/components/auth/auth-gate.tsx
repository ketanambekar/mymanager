"use client";

import { PropsWithChildren, useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useAuthStore } from "@/store/auth-store";
import { UserProfileMenu } from "@/components/auth/user-profile-menu";

const PUBLIC_PATHS = new Set(["/login"]);

export function AuthGate({ children }: PropsWithChildren) {
  const router = useRouter();
  const pathname = usePathname();
  const user = useAuthStore((state) => state.user);
  const initialized = useAuthStore((state) => state.initialized);
  const isBootstrapping = useAuthStore((state) => state.isBootstrapping);
  const bootstrap = useAuthStore((state) => state.bootstrap);

  useEffect(() => {
    void bootstrap();
  }, [bootstrap]);

  useEffect(() => {
    if (!initialized) {
      return;
    }

    const isPublicRoute = PUBLIC_PATHS.has(pathname);

    if (!user && !isPublicRoute) {
      router.replace("/login");
      return;
    }

    if (user && pathname === "/login") {
      router.replace("/");
    }
  }, [initialized, pathname, router, user]);

  if (!initialized || isBootstrapping) {
    return (
      <div className="grid min-h-screen place-items-center bg-[var(--paper)]">
        <div className="text-center">
          <p className="text-lg font-semibold tracking-tight text-[var(--ink)]">Loading your workspace...</p>
          <p className="text-sm text-zinc-500">Preparing your session</p>
        </div>
      </div>
    );
  }

  const showProfileMenu = Boolean(user && pathname !== "/login");

  return (
    <>
      {showProfileMenu ? <UserProfileMenu /> : null}
      {children}
    </>
  );
}
