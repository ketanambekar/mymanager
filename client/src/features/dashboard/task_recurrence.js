import { CUSTOM_FREQUENCY_UNITS, TASK_FREQUENCIES } from "./constants/task_frequencies.js";

export function normalizeRecurrence(recurrence) {
  const frequency = Object.values(TASK_FREQUENCIES).includes(recurrence?.frequency)
    ? recurrence.frequency : TASK_FREQUENCIES.ONE_TIME;
  if (frequency !== TASK_FREQUENCIES.CUSTOM) return { frequency };
  const interval = Number(recurrence?.interval);
  const unit = CUSTOM_FREQUENCY_UNITS.some((option) => option.value === recurrence?.unit) ? recurrence.unit : "day";
  return { frequency, interval: Number.isInteger(interval) && interval >= 1 && interval <= 365 ? interval : 1, unit };
}

export function getRecurrenceLabel(recurrence) {
  const rule = normalizeRecurrence(recurrence);
  if (rule.frequency === TASK_FREQUENCIES.ONE_TIME) return "";
  if (rule.frequency !== TASK_FREQUENCIES.CUSTOM) return rule.frequency[0].toUpperCase() + rule.frequency.slice(1);
  return `Every ${rule.interval} ${rule.unit}${rule.interval === 1 ? "" : "s"}`;
}

export function localDateString(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}