import { ProjectItem } from "@/types/dashboard";
import { Badge } from "../ui/badge";
import { Card } from "../ui/card";

const priorityClasses: Record<string, string> = {
  P1: "border-[#7e2b24] bg-[#472420] text-[#ff8f7f]",
  P2: "border-[#7a4a24] bg-[#473223] text-[#ffb777]",
  P3: "border-[#706136] bg-[#49422a] text-[#efd387]",
  P4: "border-[#4a423a] bg-[#352f2a] text-[#d6c3ad]",
};

type ProjectCardProps = {
  project: ProjectItem;
  selected?: boolean;
  onClick?: (projectId: number) => void;
  accentIndex?: number;
};

export function ProjectCard({ project, selected = false, onClick, accentIndex = 0 }: ProjectCardProps) {
  const cardClassName = selected
    ? "cursor-pointer rounded-xl border-[var(--border-strong)] bg-[var(--surface)] p-4 transition-all duration-200 hover:-translate-y-0.5"
    : "cursor-pointer rounded-xl p-4 transition-all duration-200 hover:-translate-y-0.5 hover:border-[var(--border-strong)] hover:bg-[var(--surface)]";

  return (
    <Card
      className={cardClassName}
      onClick={() => onClick?.(project.id)}
      role="button"
      tabIndex={0}
      onKeyDown={(event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          onClick?.(project.id);
        }
      }}
    >
      <div className="mb-3 flex items-center justify-between gap-2">
        <div className="inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 py-1">
          <div className="h-2.5 w-2.5 rounded-[2px]" style={{ backgroundColor: project.colorHex }} />
          <span className="text-[10px] uppercase tracking-[0.12em] text-[var(--muted)]">Project</span>
        </div>
        <Badge className={priorityClasses[project.priority]}>{project.priority}</Badge>
      </div>

      <h3 className="text-base font-extrabold text-[var(--ink)]">{project.name}</h3>
      <p className="mt-1 line-clamp-2 text-sm leading-snug text-[var(--muted)]">{project.description}</p>

      <div className="mt-4 grid grid-cols-2 gap-2 text-xs">
        <div className="rounded-lg border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 py-2">
          <p className="text-[10px] uppercase tracking-[0.1em] text-[var(--muted-soft)]">Status</p>
          <p className="mt-0.5 font-semibold text-[var(--ink)]">{project.status.replace("_", " ")}</p>
        </div>
        <div className="rounded-lg border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 py-2 text-right">
          <p className="text-[10px] uppercase tracking-[0.1em] text-[var(--muted-soft)]">Tasks</p>
          <p className="mt-0.5 font-semibold text-[var(--ink)]">{project.taskCount}</p>
        </div>
      </div>
    </Card>
  );
}
