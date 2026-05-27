"use client";

import { KanbanSquare, LayoutDashboard, Palette } from "lucide-react";
import { cn } from "@/lib/utils";
import { ProjectItem } from "@/types/dashboard";

const menu = [
  { icon: LayoutDashboard, label: "Dashboard", key: "dashboard" },
  { icon: KanbanSquare, label: "Projects", key: "projects" },
  { icon: Palette, label: "Masters", key: "masters" },
];

export type SidebarSection = "dashboard" | "projects" | "masters" | "settings";

type SidebarProps = {
  activeSection: SidebarSection;
  onSelect: (section: SidebarSection) => void;
  projects: ProjectItem[];
  selectedProjectId?: number | null;
  onOpenProjects: () => void;
  onOpenProject: (projectId: number) => void;
};

export function Sidebar({
  activeSection,
  onSelect,
  projects,
  selectedProjectId,
  onOpenProjects,
  onOpenProject,
}: SidebarProps) {
  return (
    <aside className="enter-rise w-full rounded-2xl border border-[var(--border-strong)] bg-[linear-gradient(170deg,rgba(42,37,32,0.9),rgba(23,22,20,0.96))] p-3.5 shadow-[0_14px_34px_rgba(0,0,0,0.28)] lg:sticky lg:top-4 lg:max-h-[calc(100vh-2rem)] lg:min-w-[220px] lg:overflow-y-auto">
      <div className="mb-3 px-1 py-1">
        <p className="text-[10px] uppercase tracking-[0.2em] text-[var(--muted)]">Workspace</p>
        <p className="mt-1 text-base font-extrabold">MyManager</p>
      </div>

      <nav className="space-y-1.5 rounded-xl border border-[var(--border)] bg-[var(--surface-muted)]/30 p-1.5">
        {menu.map((item) => (
          <button
            key={item.label}
            type="button"
            onClick={() => onSelect(item.key as SidebarSection)}
            className={cn(
              "group relative flex w-full items-center gap-2.5 rounded-lg border px-3 py-2.5 text-left text-sm transition-all",
              activeSection === item.key
                ? "border-[var(--border-strong)] bg-[var(--surface)] text-[var(--brand-ink)]"
                : "border-transparent text-[var(--muted)] hover:border-[var(--border)] hover:bg-[var(--surface-muted)] hover:text-[var(--ink)]",
            )}
          >
            <span
              className={cn(
                "absolute bottom-2 left-1.5 top-2 w-0.5 rounded-full bg-[var(--brand-orange)] transition-opacity",
                activeSection === item.key ? "opacity-100" : "opacity-0 group-hover:opacity-45",
              )}
            />
            <item.icon className="h-4 w-4" />
            {item.label}
          </button>
        ))}
      </nav>

      <div className="mt-4 border-t border-[var(--border)] pt-3">
        <div className="mb-2 flex items-center justify-between px-1">
          <p className="text-[10px] uppercase tracking-[0.14em] text-[var(--muted)]">Projects</p>
          <span className="text-[10px] text-[var(--muted)]">{projects.length}</span>
        </div>

        <div className="space-y-1">
          <button
            type="button"
            onClick={onOpenProjects}
            className={cn(
              "w-full rounded-md px-2.5 py-2 text-left text-xs transition-colors",
              selectedProjectId === null
                ? "bg-[var(--surface)] text-[var(--ink)]"
                : "text-[var(--muted)] hover:bg-[var(--surface-muted)] hover:text-[var(--ink)]",
            )}
          >
            All projects
          </button>

          <div className="max-h-64 space-y-1 overflow-auto pr-1">
            {projects.map((project) => (
              <button
                key={project.id}
                type="button"
                onClick={() => onOpenProject(project.id)}
                className={cn(
                  "flex w-full items-center justify-between gap-2 rounded-md px-2.5 py-2 text-left text-xs transition-colors",
                  selectedProjectId === project.id
                    ? "bg-[var(--surface)] text-[var(--ink)]"
                    : "text-[var(--muted)] hover:bg-[var(--surface-muted)] hover:text-[var(--ink)]",
                )}
              >
                <span className="flex min-w-0 items-center gap-2">
                  <span className="h-2 w-2 rounded-full" style={{ backgroundColor: project.colorHex }} />
                  <span className="truncate">{project.name}</span>
                </span>
                <span className="shrink-0 text-[10px] text-[var(--muted)]">{project.taskCount}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </aside>
  );
}
