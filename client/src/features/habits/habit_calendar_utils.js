export function formatHabitDate(date, options = { day: "numeric", month: "long", year: "numeric" }) {
  return new Intl.DateTimeFormat("en-GB", { ...options, timeZone: "UTC" }).format(new Date(`${date}T00:00:00Z`));
}

export function shiftHabitMonth(month, offset) {
  const [year, number] = month.split("-").map(Number);
  const date = new Date(Date.UTC(year, number - 1 + offset, 1));
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}`;
}

export function calendarPadding(days) {
  const leading = (new Date(`${days[0].date}T00:00:00Z`).getUTCDay() + 6) % 7;
  return { leading, trailing: (7 - (leading + days.length) % 7) % 7 };
}

export function isHabitHistoryDate(date, calendar) {
  return Boolean(calendar.firstRecordedDate && calendar.lastRecordedDate
    && date >= calendar.firstRecordedDate && date <= calendar.lastRecordedDate);
}

export function nearestHabitMonth(months, currentMonth) {
  const monthIndex = (month) => {
    const [year, number] = month.split("-").map(Number);
    return year * 12 + number - 1;
  };
  const current = monthIndex(currentMonth);
  return months.reduce((nearest, month) => {
    if (!nearest) return month;
    const distance = Math.abs(monthIndex(month) - current);
    const previousDistance = Math.abs(monthIndex(nearest) - current);
    return distance < previousDistance || distance === previousDistance && month < nearest ? month : nearest;
  }, null);
}

export function adjacentHabitMonths(months, currentMonth) {
  return {
    previous: months.filter((month) => month < currentMonth).at(-1) ?? null,
    next: months.find((month) => month > currentMonth) ?? null,
  };
}

export function habitHistoryYears(months) {
  return [...new Set(months.map((month) => Number(month.slice(0, 4))))];
}

export function adjacentHabitYears(months, currentYear) {
  const years = habitHistoryYears(months);
  return {
    previous: years.filter((year) => year < currentYear).at(-1) ?? null,
    next: years.find((year) => year > currentYear) ?? null,
  };
}

export function formatHabitPeriod(period, unit) {
  if (unit === "year") return period.startDate.slice(0, 4);
  if (unit === "month") return formatHabitDate(period.startDate, { month: "long", year: "numeric" });
  if (unit === "week") return `${formatHabitDate(period.startDate, { day: "numeric", month: "short", year: "numeric" })} - ${formatHabitDate(period.endDate, { day: "numeric", month: "short", year: "numeric" })}`;
  return formatHabitDate(period.startDate);
}

export function formatHabitTimestamp(timestamp, timezone) {
  return new Intl.DateTimeFormat("en-GB", {
    timeZone: timezone, day: "numeric", month: "short", year: "numeric",
    hour: "2-digit", minute: "2-digit", second: "2-digit", hourCycle: "h23",
  }).format(new Date(timestamp));
}
