export function reportRate(value) {
  return value === null ? "No rated data" : `${value}%`;
}

export function reportDate(value, options = { month: "short", day: "numeric" }) {
  return new Intl.DateTimeFormat(undefined, { ...options, timeZone: "UTC" }).format(new Date(`${value}T12:00:00Z`));
}

export function reportTimestamp(value, timezone) {
  return new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short", timeZone: timezone }).format(new Date(value));
}

export function activityCalendar(year, activityDays) {
  const recorded = new Map(activityDays.map((day) => [day.date, day]));
  return Array.from({ length: 12 }, (_, month) => {
    const first = new Date(Date.UTC(year, month, 1));
    const prefix = (first.getUTCDay() + 6) % 7;
    const count = new Date(Date.UTC(year, month + 1, 0)).getUTCDate();
    return {
      month: `${year}-${String(month + 1).padStart(2, "0")}`,
      padding: prefix,
      days: Array.from({ length: count }, (_, index) => {
        const date = `${year}-${String(month + 1).padStart(2, "0")}-${String(index + 1).padStart(2, "0")}`;
        const activity = recorded.get(date);
        const total = activity ? activity.completed + activity.skipped + activity.missed : 0;
        return { date, activity, total, level: total === 0 ? 0 : total === 1 ? 1 : total <= 3 ? 2 : total <= 6 ? 3 : 4 };
      }),
    };
  });
}
