export const HABIT_STATES = Object.freeze([
  { id: "COMPLETED", label: "Done", symbol: "check" },
  { id: "SKIPPED", label: "Skipped", symbol: "skip" },
  { id: "MISSED", label: "Missed", symbol: "miss" },
  { id: "PENDING", label: "Pending today", symbol: "pending" },
  { id: "OVERDUE", label: "Overdue", symbol: "overdue" },
  { id: "SCHEDULED", label: "Scheduled", symbol: "scheduled" },
  { id: "NOT_RECORDED", label: "Not recorded", symbol: "empty" },
  { id: "NOT_DAILY", label: "Not a daily occurrence", symbol: "other" },
]);

export const HABIT_WEEKDAYS = Object.freeze(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]);
