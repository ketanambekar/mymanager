export const REPORT_YEARS = Array.from({ length: 300 }, (_, index) => 2199 - index);

export const REPORT_OUTCOMES = [
  { key: "completed", label: "Completed" },
  { key: "skipped", label: "Skipped" },
  { key: "missed", label: "Missed" },
  { key: "open", label: "Open" },
];

export const REPORT_ACTIVITY = REPORT_OUTCOMES.filter(({ key }) => key !== "open");
