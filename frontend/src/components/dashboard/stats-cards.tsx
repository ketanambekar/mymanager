import { ChartColumnIncreasing, ListChecks, Rocket, ShieldAlert } from "lucide-react";
import { Card } from "../ui/card";

type StatsCardsProps = {
  projectCount: number;
  taskCount: number;
  activeCount: number;
  urgentCount: number;
};

const statsConfig = [
  { icon: Rocket, label: "Projects", key: "projectCount", hint: "Ships in motion" },
  { icon: ListChecks, label: "Tasks", key: "taskCount", hint: "Total workload" },
  { icon: ChartColumnIncreasing, label: "Active", key: "activeCount", hint: "Now executing" },
  { icon: ShieldAlert, label: "Urgent", key: "urgentCount", hint: "Needs captain" },
] as const;

export function StatsCards({ projectCount, taskCount, activeCount, urgentCount }: StatsCardsProps) {
  const statsMap = { projectCount, taskCount, activeCount, urgentCount };

  return (
    <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-6">
      {statsConfig.map((stat, index) => (
        <Card
          key={stat.key}
          className={
            index === 0
              ? "p-3 sm:col-span-2"
              : index === 1
                ? "p-3 sm:col-span-2"
                : "p-3"
          }
        >
          <div className="mb-2 inline-flex rounded-lg border border-[var(--border)] bg-[var(--surface-muted)] p-2 text-[var(--brand-orange)]">
            <stat.icon className="h-4 w-4" />
          </div>
          <p className="text-[10px] uppercase tracking-[0.14em] text-[var(--muted-soft)]">{stat.label}</p>
          <p className="mt-1 text-xl font-extrabold text-[var(--ink)] sm:text-2xl">{statsMap[stat.key]}</p>
          <p className="mt-0.5 text-xs text-[var(--muted)]">{stat.hint}</p>
        </Card>
      ))}
    </div>
  );
}
