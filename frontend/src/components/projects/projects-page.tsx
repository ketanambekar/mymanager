"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { CalendarDays } from "lucide-react";
import { Sidebar, SidebarSection } from "@/components/dashboard/sidebar";
import { ProjectCard } from "@/components/dashboard/project-card";
import { Button } from "@/components/ui/button";
import { useDashboardStore } from "@/store/dashboard-store";

export function ProjectsPage() {
  const router = useRouter();
  const { projects, loadDashboard, isLoading, error } = useDashboardStore();

  useEffect(() => {
    void loadDashboard();
  }, [loadDashboard]);

  function handleSelect(section: SidebarSection) {
    if (section === "projects") {
      return;
    }

    router.push("/");
  }

  return (
    <div className="grain-layer min-h-screen px-3 py-4 text-[var(--ink)] sm:px-4 lg:px-6">
      <div className="relative mx-auto flex w-full max-w-[1600px] flex-col gap-4 lg:flex-row lg:items-start">
        <div className="w-full lg:w-[220px] lg:flex-none">
          <Sidebar
            activeSection="projects"
            onSelect={handleSelect}
            projects={projects}
            selectedProjectId={null}
            onOpenProjects={() => router.push("/projects")}
            onOpenProject={(projectId) => router.push(`/projects/${projectId}`)}
          />
        </div>

        <main className="min-w-0 flex-1 space-y-4">
          <header className="enter-rise rounded-2xl border border-[var(--border-strong)] bg-[linear-gradient(165deg,rgba(42,37,32,0.9),rgba(23,22,20,0.96))] p-5 shadow-[0_14px_34px_rgba(0,0,0,0.28)]">
            <div className="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
              <div className="min-w-0 max-w-2xl">
                <div className="mb-2 inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1 text-[11px] uppercase tracking-[0.14em] text-[var(--muted)]">
                  <CalendarDays className="h-3.5 w-3.5" />
                  Projects directory
                </div>
                <h1 className="text-[1.8rem] font-extrabold sm:text-[2.4rem]">Projects</h1>
                <p className="mt-1 max-w-xl text-sm leading-6 text-[var(--muted)]">
                  Browse active workspaces and jump straight into planning, execution, and tracking.
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-2 xl:justify-end">
                <div className="rounded-full border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1.5 text-xs text-[var(--muted)]">
                  {projects.length} projects available
                </div>
                <Button variant="secondary" onClick={() => router.push("/")}>
                  Back to dashboard
                </Button>
              </div>
            </div>
          </header>

          <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
            <div className="rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-3.5">
              <p className="text-[11px] uppercase tracking-[0.12em] text-[var(--muted)]">Total projects</p>
              <p className="mt-1 text-2xl font-extrabold">{projects.length}</p>
            </div>
            <div className="rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-3.5">
              <p className="text-[11px] uppercase tracking-[0.12em] text-[var(--muted)]">With tasks</p>
              <p className="mt-1 text-2xl font-extrabold">{projects.filter((project) => project.taskCount > 0).length}</p>
            </div>
            <div className="rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-3.5">
              <p className="text-[11px] uppercase tracking-[0.12em] text-[var(--muted)]">High priority</p>
              <p className="mt-1 text-2xl font-extrabold">{projects.filter((project) => project.priority === "P1").length}</p>
            </div>
          </section>

          {error ? (
            <div className="rounded-md border border-[color:var(--danger)]/60 bg-[#3d1f1b] px-3 py-2.5 text-sm text-[#ffb0a2]">
              {error}
            </div>
          ) : null}

          <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {projects.map((project, index) => (
              <ProjectCard
                key={project.id}
                project={project}
                accentIndex={index}
                onClick={(projectId) => router.push(`/projects/${projectId}`)}
              />
            ))}
          </section>

          {!projects.length && !isLoading ? (
            <div className="rounded-xl border border-dashed border-[var(--border-strong)] bg-[var(--surface-muted)] p-4 text-sm text-[var(--muted)]">
              No projects are available yet. Use the dashboard to create the first one.
            </div>
          ) : null}
        </main>
      </div>
    </div>
  );
}
