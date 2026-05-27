import { cn } from "@/lib/utils";
import { HTMLAttributes } from "react";

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "overflow-hidden rounded-xl border border-[var(--border)] bg-[linear-gradient(160deg,rgba(42,37,32,0.9),rgba(23,22,20,0.95))] shadow-[0_14px_30px_rgba(0,0,0,0.22)]",
        className,
      )}
      {...props}
    />
  );
}
