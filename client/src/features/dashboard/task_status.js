export const TASK_STATUSES = Object.freeze({
  OPEN: "OPEN",
  COMPLETED: "COMPLETED",
  SKIPPED: "SKIPPED",
  MISSED: "MISSED",
});

export function getTaskStatus(task) {
  return task.status ?? (task.completed ? TASK_STATUSES.COMPLETED : TASK_STATUSES.OPEN);
}
