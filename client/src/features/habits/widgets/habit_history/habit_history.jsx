import { ChevronLeft, ChevronRight } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import { getRecurrenceLabel } from "@/features/dashboard/task_recurrence.js";
import { adjacentHabitYears, formatHabitDate, formatHabitPeriod } from "@/features/habits/habit_calendar_utils.js";
import HabitState from "../habit_state/habit_state.jsx";
import "./habit_history.css";

export default function HabitHistory({ history, selectedDate, onSelectOccurrence, onChangeYear, onThisYear }) {
  const { previous, next } = adjacentHabitYears(history.availableMonths, history.year);
  const hasHistory = history.availableMonths.length > 0;
  return (
    <section aria-labelledby="habit-history-heading" className={`habit-history-panel habit-history-panel--${history.periodUnit}`}>
      <div className="habit-history-heading"><p>{history.habit.project?.name ?? "General"}</p><h2 id="habit-history-heading">{history.habit.title}</h2><span className="habit-cadence">{getRecurrenceLabel(history.habit.recurrence)}</span></div>
      <div className="habit-history-toolbar">
        <AppIconButton aria-label="Previous recorded year" disabled={previous === null} onClick={() => onChangeYear(-1)}><ChevronLeft aria-hidden="true" size={18} /></AppIconButton>
        <h3 aria-live="polite">{history.year}</h3>
        <AppIconButton aria-label="Next recorded year" disabled={next === null} onClick={() => onChangeYear(1)}><ChevronRight aria-hidden="true" size={18} /></AppIconButton>
        <AppButton disabled={!hasHistory} onClick={onThisYear} variant="secondary">This year</AppButton>
      </div>
      <dl className="habit-history-totals">
        <div><dt>Completed occurrences</dt><dd>{history.summary.completedOccurrences}</dd></div>
        <div><dt>Skipped occurrences</dt><dd>{history.summary.skippedOccurrences}</dd></div>
        <div><dt>Missed occurrences</dt><dd>{history.summary.missedOccurrences}</dd></div>
      </dl>
      <p className="habit-history-coverage">{history.summary.recordedOccurrences} saved occurrences in {history.year}.</p>
      {history.periodUnit === "week" && <p className="habit-history-note">Weeks run Monday-Sunday. Boundary weeks include only occurrences due in {history.year}.</p>}
      {history.periods.length ? <ol className="habit-period-list">
        {history.periods.map((period) => <li className="habit-period" key={period.startDate}>
          <header><h4>{formatHabitPeriod(period, history.periodUnit)}</h4><span>{period.summary.recordedOccurrences} occurrences</span></header>
          <div className="habit-period-counts" aria-label="Period occurrence counts"><span>Done {period.summary.completedOccurrences}</span><span>Skipped {period.summary.skippedOccurrences}</span><span>Missed {period.summary.missedOccurrences}</span></div>
          <ul className="habit-occurrence-list">{period.occurrences.map((entry) => <li key={entry.occurrence.taskId}><button aria-pressed={entry.date === selectedDate} className="habit-occurrence" onClick={() => onSelectOccurrence(entry.date)} type="button">
            <span className="habit-occurrence-date">{formatHabitDate(entry.date, { day: "numeric", month: "short", year: "numeric" })}{entry.isToday && <small>Today</small>}</span>
            <span className="habit-occurrence-copy"><strong>{entry.occurrence.title}</strong><small>{getRecurrenceLabel(entry.occurrence.recurrence) || "One time"}</small>{entry.occurrence.closeReason && <span className="habit-occurrence-reason">{entry.occurrence.closeReason}</span>}</span>
            <HabitState state={entry.state} />
          </button></li>)}</ul>
        </li>)}
      </ol> : <div className="habit-placeholder"><h3>{hasHistory ? "No saved occurrences this year" : "No dated history"}</h3><p>{hasHistory ? "Choose a recorded year to view its history." : "This habit has no saved dated occurrences to show."}</p></div>}
      <p className="habit-history-note">Only saved task occurrences are shown. Empty periods do not mean the habit was missed.</p>
      {history.undatedOccurrencesCount > 0 && <p className="habit-notice">{history.undatedOccurrencesCount} undated occurrences cannot be placed in this history.</p>}
    </section>
  );
}
