import { cn } from "@/lib/utils";
import { HTMLAttributes } from "react";

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "overflow-hidden rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] shadow-[0_10px_24px_rgba(0,0,0,0.18)]",
        className,
      )}
      {...props}
    />
  );
}
