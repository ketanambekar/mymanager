import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-lg border text-sm font-semibold tracking-[0.01em] transition-all duration-150 active:translate-y-px disabled:pointer-events-none disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-orange)] focus-visible:ring-offset-0",
  {
    variants: {
      variant: {
        primary:
          "border-[color:var(--brand-red)] bg-[linear-gradient(135deg,var(--brand-red),#b82322)] text-white shadow-[0_4px_0_#761515,0_10px_20px_rgba(0,0,0,0.25)] hover:-translate-y-px hover:brightness-110",
        secondary:
          "border-[var(--border-strong)] bg-[var(--surface)] text-[var(--ink)] shadow-[0_2px_0_#161311,0_8px_16px_rgba(0,0,0,0.18)] hover:border-[var(--brand-orange)] hover:bg-[var(--surface-strong)]",
        ghost: "border-transparent bg-transparent text-[var(--muted)] hover:text-[var(--ink)] hover:bg-[var(--surface-muted)]",
      },
      size: {
        md: "h-9 px-3.5",
        lg: "h-10 px-4",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  },
);

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement>, VariantProps<typeof buttonVariants> {}

export function Button({ className, variant, size, ...props }: ButtonProps) {
  return <button className={cn(buttonVariants({ variant, size }), className)} {...props} />;
}
