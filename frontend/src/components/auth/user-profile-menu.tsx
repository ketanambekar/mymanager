"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/store/auth-store";
import { Button } from "@/components/ui/button";

function initialsFromName(name: string | undefined): string {
  if (!name) {
    return "MM";
  }

  return name
    .split(" ")
    .map((part) => part.charAt(0).toUpperCase())
    .slice(0, 2)
    .join("");
}

export function UserProfileMenu() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const user = useAuthStore((state) => state.user);
  const logout = useAuthStore((state) => state.logout);

  const initials = useMemo(() => initialsFromName(user?.name), [user?.name]);

  async function handleLogout() {
    await logout();
    router.replace("/login");
  }

  function openProfile() {
    setOpen(false);
    router.push("/profile");
  }

  if (!user) {
    return null;
  }

  return (
    <div className="fixed right-4 top-4 z-50">
      <div className="relative">
        <button
          type="button"
          onClick={() => setOpen((value) => !value)}
          className="flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--paper)] px-3 py-1.5 text-left shadow-sm"
        >
          {user.avatarUrl ? (
            <img
              src={user.avatarUrl}
              alt={user.name}
              className="h-8 w-8 rounded-full border border-[var(--border)] object-cover"
              referrerPolicy="no-referrer"
            />
          ) : (
            <span className="grid h-8 w-8 place-items-center rounded-full bg-[var(--brand-orange)] text-xs font-semibold text-white">{initials}</span>
          )}
          <span className="hidden text-sm font-medium sm:block">{user.name}</span>
        </button>

        {open ? (
          <div className="absolute right-0 mt-2 w-72 rounded-2xl border border-[var(--border)] bg-[var(--paper-elevated)] p-3 shadow-xl">
            <button
              type="button"
              onClick={openProfile}
              className="w-full rounded-lg p-2 text-left transition-colors hover:bg-[var(--surface-muted)]"
            >
              <p className="text-sm font-semibold text-[var(--ink)]">{user.name}</p>
              <p className="text-xs text-[var(--muted)]">{user.email}</p>
            </button>
            <div className="mt-3">
              <Button type="button" variant="secondary" className="w-full" onClick={handleLogout}>
                Logout
              </Button>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
