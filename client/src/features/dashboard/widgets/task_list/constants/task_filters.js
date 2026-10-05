export const TASK_FILTER_IDS = Object.freeze({
  ALL: "all",
  OPEN: "open",
  COMPLETED: "completed",
  SKIPPED: "skipped",
  MISSED: "missed",
});

export const TASK_FILTERS = Object.freeze([
  { id: TASK_FILTER_IDS.ALL, label: "All tasks" },
  { id: TASK_FILTER_IDS.OPEN, label: "To do" },
  { id: TASK_FILTER_IDS.COMPLETED, label: "Completed" },
  { id: TASK_FILTER_IDS.SKIPPED, label: "Skipped" },
  { id: TASK_FILTER_IDS.MISSED, label: "Missed" },
]);
