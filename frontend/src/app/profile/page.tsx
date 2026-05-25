"use client";

import { useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, CalendarDays, CheckCircle2 } from "lucide-react";
import { Sidebar, SidebarSection } from "@/components/dashboard/sidebar";
import { Button } from "@/components/ui/button";
import { useAuthStore } from "@/store/auth-store";
import { useDashboardStore } from "@/store/dashboard-store";

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

function formatDateTime(value?: string | null): string {
  if (!value) {
    return "N/A";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "N/A";
  }

  return new Intl.DateTimeFormat("en-US", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}

export default function ProfilePage() {
  const router = useRouter();
  const user = useAuthStore((state) => state.user);
  const { projects, selectedProjectId, activePanel, setSelectedProjectId, setActivePanel, loadDashboard } = useDashboardStore();

  const initials = useMemo(() => initialsFromName(user?.name), [user?.name]);
  const isEmailVerified = Boolean(user?.emailVerifiedAt);
  const sidebarActiveSection: SidebarSection =
    activePanel === "dashboard" || activePanel === "projects" || activePanel === "masters" || activePanel === "settings"
      ? activePanel
      : "projects";
  const todayLabel = new Intl.DateTimeFormat("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  }).format(new Date());

  useEffect(() => {
    if (projects.length > 0) {
      return;
    }

    void loadDashboard();
  }, [loadDashboard, projects.length]);

  if (!user) {
    return null;
  }

  function handleSidebarSelect(section: SidebarSection) {
    setActivePanel(section);
    router.push("/");
  }

  function handleOpenProjects() {
    setSelectedProjectId(null);
    setActivePanel("projects");
    router.push("/");
  }

  function handleOpenProject(projectId: number) {
    setSelectedProjectId(projectId);
    setActivePanel("projects");
    router.push("/");
  }

  return (
    <main className="grain-layer min-h-screen px-3 py-4 text-[var(--ink)] sm:px-4 lg:px-6">
      <div className="relative mx-auto flex w-full max-w-none flex-col gap-4 lg:flex-row lg:items-start">
        <div className="w-full lg:w-[220px] lg:flex-none">
          <Sidebar
            activeSection={sidebarActiveSection}
            onSelect={handleSidebarSelect}
            projects={projects}
            selectedProjectId={selectedProjectId}
            onOpenProjects={handleOpenProjects}
            onOpenProject={handleOpenProject}
          />
        </div>

        <section className="min-w-0 flex-1 space-y-4">
          <header className="rounded-2xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <div className="inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1 text-[11px] uppercase tracking-[0.14em] text-[var(--muted)]">
                  <CalendarDays className="h-3.5 w-3.5" />
                  {todayLabel}
                </div>
                <p className="mt-2 text-xs uppercase tracking-[0.12em] text-[var(--muted)]">Account</p>
                <h1 className="mt-1 text-2xl font-extrabold">Profile</h1>
              </div>
              <Button type="button" variant="secondary" onClick={() => router.push("/")}>
                <ArrowLeft className="mr-1.5 h-4 w-4" /> Back to dashboard
              </Button>
            </div>
          </header>

          <section className="rounded-2xl border border-[var(--border)] bg-[var(--paper-elevated)] p-6">
            <div className="flex flex-col items-center gap-4 text-center sm:flex-row sm:text-left">
              {user.avatarUrl ? (
                <img
                  src={user.avatarUrl}
                  alt={user.name}
                  className="h-24 w-24 rounded-full border border-[var(--border-strong)] object-cover"
                  referrerPolicy="no-referrer"
                />
              ) : (
                <div className="grid h-24 w-24 place-items-center rounded-full bg-[var(--brand-orange)] text-2xl font-bold text-white">
                  {initials}
                </div>
              )}

              <div>
                <div className="flex items-center justify-center gap-2 sm:justify-start">
                  <h2 className="text-xl font-bold text-[var(--ink)]">{user.name}</h2>
                  {isEmailVerified ? (
                    <span
                      title="Email verified"
                      aria-label="Email verified"
                      className="inline-flex items-center rounded-full border border-[#2f8458] bg-[#1f3a2c] p-1 text-[#7ef0b2]"
                    >
                      <CheckCircle2 className="h-4 w-4" />
                    </span>
                  ) : null}
                </div>
                <p className="text-sm text-[var(--muted)]">{user.email}</p>
                <div className="mt-2 inline-flex items-center gap-2 rounded-full border border-[#2f8458] bg-[#1b2f24] px-3 py-1 text-xs font-semibold uppercase tracking-[0.08em] text-[#7ef0b2]">
                  <span className="relative inline-flex h-2.5 w-2.5">
                    <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-[#41d68a] opacity-75" />
                    <span className="relative inline-flex h-2.5 w-2.5 rounded-full bg-[#41d68a]" />
                  </span>
                  Active
                </div>
              </div>
            </div>

            <div className="mt-6 grid gap-2 sm:grid-cols-2">
              <div className="rounded-lg border border-[var(--border)] bg-[var(--surface-muted)] p-3">
                <p className="text-[10px] uppercase tracking-[0.12em] text-[var(--muted-soft)]">Created At</p>
                <p className="mt-1 text-sm font-semibold text-[var(--ink)]">{formatDateTime(user.createdAt)}</p>
              </div>
              <div className="rounded-lg border border-[var(--border)] bg-[var(--surface-muted)] p-3">
                <p className="text-[10px] uppercase tracking-[0.12em] text-[var(--muted-soft)]">Last Updated</p>
                <p className="mt-1 text-sm font-semibold text-[var(--ink)]">{formatDateTime(user.updatedAt)}</p>
              </div>
              <div className="rounded-lg border border-[var(--border)] bg-[var(--surface-muted)] p-3 sm:col-span-2">
                <p className="text-[10px] uppercase tracking-[0.12em] text-[var(--muted-soft)]">authProvider</p>
                <p className="mt-1 text-sm font-semibold text-[var(--ink)]">{user.authProvider ?? user.provider ?? "GOOGLE"}</p>
              </div>
            </div>
          </section>
        </section>
      </div>
    </main>
  );
}
