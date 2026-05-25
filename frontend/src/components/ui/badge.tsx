import { ReactNode } from "react";
import { cn } from "@/lib/utils";

type BadgeProps = {
  children: ReactNode;
  className?: string;
};

export function Badge({ children, className }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-sm border border-[var(--border-strong)] bg-[var(--surface-muted)] px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.08em] text-[var(--ink)]",
        className,
      )}
    >
      {children}
    </span>
  );
}
