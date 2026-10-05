import { TaskStatus } from "@prisma/client";
import { AppError } from "../../shared/app_error.js";

export type ClosureAction = "skip" | "miss";

export const closureStatus: Record<ClosureAction, TaskStatus> = { skip: TaskStatus.SKIPPED, miss: TaskStatus.MISSED };
export const closedStatuses: TaskStatus[] = [TaskStatus.SKIPPED, TaskStatus.MISSED];

export function isClosedStatus(status: TaskStatus): boolean {
  return closedStatuses.includes(status);
}

export function assertCanReopen(status: TaskStatus): void {
  if (isClosedStatus(status)) {
    throw new AppError("TASK_NOT_REOPENABLE", "Skipped and missed tasks cannot be reopened", 409);
  }
}

type ClosureCandidate = { status: TaskStatus; dueDate: string | null; recurring: boolean };

/** Returns "replay" when the occurrence already has the requested state so retries succeed without side effects. */
export function closureOutcome(task: ClosureCandidate, action: ClosureAction, today: string): "apply" | "replay" {
  if (task.status === closureStatus[action]) return "replay";
  if (task.status !== TaskStatus.OPEN) throw new AppError("TASK_NOT_OPEN", "Only open tasks can be skipped or marked missed", 409);
  if (action === "skip" && !task.recurring) throw new AppError("TASK_NOT_RECURRING", "Only recurring tasks can be skipped", 409);
  if (!task.dueDate || task.dueDate >= today) throw new AppError("TASK_NOT_OVERDUE", "Only overdue tasks can be skipped or marked missed", 409);
  return "apply";
}
