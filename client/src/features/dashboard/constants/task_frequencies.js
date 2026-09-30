export const TASK_FREQUENCIES = Object.freeze({
  ONE_TIME: "one_time",
  DAILY: "daily",
  WEEKLY: "weekly",
  MONTHLY: "monthly",
  YEARLY: "yearly",
  CUSTOM: "custom",
});

export const TASK_FREQUENCY_OPTIONS = Object.freeze([
  { value: TASK_FREQUENCIES.ONE_TIME, label: "One time" },
  { value: TASK_FREQUENCIES.DAILY, label: "Daily" },
  { value: TASK_FREQUENCIES.WEEKLY, label: "Weekly" },
  { value: TASK_FREQUENCIES.MONTHLY, label: "Monthly" },
  { value: TASK_FREQUENCIES.YEARLY, label: "Yearly" },
  { value: TASK_FREQUENCIES.CUSTOM, label: "Custom" },
]);

export const CUSTOM_FREQUENCY_UNITS = Object.freeze([
  { value: "day", label: "Days" },
  { value: "week", label: "Weeks" },
  { value: "month", label: "Months" },
  { value: "year", label: "Years" },
]);