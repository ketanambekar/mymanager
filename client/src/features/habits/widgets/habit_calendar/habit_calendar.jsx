import { ChevronLeft, ChevronRight } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import { HABIT_STATES, HABIT_WEEKDAYS } from "@/features/habits/constants/habit_states.js";
import { calendarPadding, formatHabitDate } from "@/features/habits/habit_calendar_utils.js";
import HabitState from "../habit_state/habit_state.jsx";
import "./habit_calendar.css";

export default function HabitCalendar({ calendar, selectedDate, onSelectDay, onChangeMonth, onThisMonth }) {
  const { leading, trailing } = calendarPadding(calendar.days);
  return (
    <section aria-labelledby="habit-calendar-heading" className="habit-calendar-panel">
      <div className="habit-calendar-heading"><div><p>{calendar.habit.project?.name ?? "General"}</p><h2 id="habit-calendar-heading">{calendar.habit.title}</h2></div><span className="habit-read-only">Read-only history</span></div>
      <div className="habit-month-toolbar">
        <div className="habit-month-switcher">
          <AppIconButton aria-label="Previous month" disabled={calendar.month === "1900-01"} onClick={() => onChangeMonth(-1)}><ChevronLeft aria-hidden="true" size={18} /></AppIconButton>
          <h3 aria-live="polite">{formatHabitDate(`${calendar.month}-01`, { month: "long", year: "numeric" })}</h3>
          <AppIconButton aria-label="Next month" disabled={calendar.month === "2199-12"} onClick={() => onChangeMonth(1)}><ChevronRight aria-hidden="true" size={18} /></AppIconButton>
        </div>
        <AppButton onClick={onThisMonth} variant="secondary">This month</AppButton>
      </div>
      <dl className="habit-month-totals" aria-label="Selected month totals">
        <div><dt>Done</dt><dd>{calendar.summary.completedDays}</dd></div>
        <div><dt>Skipped</dt><dd>{calendar.summary.skippedDays}</dd></div>
        <div><dt>Missed</dt><dd>{calendar.summary.missedDays}</dd></div>
      </dl>
      <p className="habit-coverage">{calendar.summary.recordedDays} of {calendar.summary.daysInMonth} days have saved occurrences.</p>
      <div aria-label={`${formatHabitDate(`${calendar.month}-01`, { month: "long", year: "numeric" })} habit calendar`} className="habit-calendar-grid">
        {HABIT_WEEKDAYS.map((day) => <span aria-hidden="true" className="habit-weekday" key={day}>{day}</span>)}
        {Array.from({ length: leading }, (_, index) => <span aria-hidden="true" key={`leading-${index}`} />)}
        {calendar.days.map((day) => {
          const label = HABIT_STATES.find((state) => state.id === day.state)?.label ?? day.state;
          const reason = ["SKIPPED", "MISSED"].includes(day.state) ? day.occurrence?.closeReason : null;
          return <button aria-label={`${formatHabitDate(day.date)}, ${label}${day.isToday ? ", today" : ""}`} aria-pressed={selectedDate === day.date} aria-current={day.isToday ? "date" : undefined} className={`habit-day habit-day--${day.state.toLowerCase()}`} key={day.date} onClick={() => onSelectDay(day.date)} type="button">
            <span>{Number(day.date.slice(-2))}</span><HabitState iconOnly state={day.state} />{day.isToday && <span className="habit-today-dot" aria-hidden="true" />}
            {reason && <span className="habit-day-reason-preview" title={reason}>{reason}</span>}
          </button>;
        })}
        {Array.from({ length: trailing }, (_, index) => <span aria-hidden="true" key={`trailing-${index}`} />)}
      </div>
      <ul aria-label="Calendar state legend" className="habit-legend">{HABIT_STATES.map((state) => <li key={state.id}><HabitState state={state.id} /></li>)}</ul>
      {!calendar.summary.recordedDays && <p className="habit-notice">No saved occurrences in this month.</p>}
      <p className="habit-history-note">Only saved task occurrences are shown. Gaps do not mean the habit was missed.</p>
      {calendar.undatedOccurrencesCount > 0 && <p className="habit-notice">{calendar.undatedOccurrencesCount} undated {calendar.undatedOccurrencesCount === 1 ? "occurrence cannot" : "occurrences cannot"} be placed on this calendar.</p>}
    </section>
  );
}
