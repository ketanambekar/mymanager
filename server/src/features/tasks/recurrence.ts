export type RecurrenceRule = {
  frequency: "one_time" | "daily" | "weekly" | "monthly" | "yearly" | "custom";
  interval?: number | null;
  unit?: "day" | "week" | "month" | "year" | null;
};

function parseDate(value: string): Date {
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime())) throw new Error("Invalid date");
  return date;
}

function formatDate(value: Date): string {
  return value.toISOString().slice(0, 10);
}

function ruleStep(rule: RecurrenceRule): { interval: number; unit: "day" | "week" | "month" | "year" } | null {
  if (rule.frequency === "one_time") return null;
  if (rule.frequency === "daily") return { interval: 1, unit: "day" };
  if (rule.frequency === "weekly") return { interval: 1, unit: "week" };
  if (rule.frequency === "monthly") return { interval: 1, unit: "month" };
  if (rule.frequency === "yearly") return { interval: 1, unit: "year" };
  return { interval: rule.interval ?? 1, unit: rule.unit ?? "day" };
}

function addPeriod(anchor: Date, unit: "day" | "week" | "month" | "year", interval: number): Date {
  const year = anchor.getUTCFullYear();
  const month = anchor.getUTCMonth();
  const day = anchor.getUTCDate();
  if (unit === "day" || unit === "week") return new Date(Date.UTC(year, month, day + interval * (unit === "week" ? 7 : 1)));
  const target = new Date(Date.UTC(year + (unit === "year" ? interval : 0), month + (unit === "month" ? interval : 0), 1));
  const lastDay = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate();
  target.setUTCDate(Math.min(day, lastDay));
  return target;
}

export function nextOccurrenceDate(dueDate: string, rule: RecurrenceRule, afterDate: string): string | null {
  const step = ruleStep(rule);
  if (!step) return null;
  const anchor = parseDate(dueDate);
  const after = parseDate(afterDate);
  let periods = 1;
  let result = addPeriod(anchor, step.unit, step.interval * periods);
  while (result <= after) {
    periods += 1;
    result = addPeriod(anchor, step.unit, step.interval * periods);
  }
  return formatDate(result);
}

export function latestOccurrenceDate(dueDate: string, rule: RecurrenceRule, onDate: string): string | null {
  const step = ruleStep(rule);
  if (!step) return null;
  const anchor = parseDate(dueDate);
  const on = parseDate(onDate);
  let periods = 1;
  let latest: Date | null = null;
  let candidate = addPeriod(anchor, step.unit, step.interval * periods);
  while (candidate <= on) {
    latest = candidate;
    periods += 1;
    candidate = addPeriod(anchor, step.unit, step.interval * periods);
  }
  return latest ? formatDate(latest) : null;
}

export function dateInTimeZone(date: Date, timeZone: string): string {
  const parts = new Intl.DateTimeFormat("en-CA", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(date);
  const value = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${value.year}-${value.month}-${value.day}`;
}