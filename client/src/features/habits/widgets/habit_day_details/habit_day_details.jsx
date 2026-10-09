import { formatHabitDate, formatHabitTimestamp } from "@/features/habits/habit_calendar_utils.js";
import HabitState from "../habit_state/habit_state.jsx";
import "./habit_day_details.css";

export default function HabitDayDetails({ day, timezone }) {
  if (!day) return null;
  const occurrence = day.occurrence;
  return (
    <section aria-labelledby="habit-day-heading" aria-live="polite" className="habit-day-details">
      <div className="habit-day-details-heading"><h3 id="habit-day-heading">{formatHabitDate(day.date)}</h3><HabitState state={day.state} /></div>
      {occurrence ? <>
        {occurrence.closeReason && <div className="habit-reason-callout"><h4>{day.state === "SKIPPED" ? "Why skipped" : day.state === "MISSED" ? "Why missed" : "Saved reason"}</h4><p>{occurrence.closeReason}</p></div>}
        <dl>
          <div><dt>Recorded task</dt><dd>{occurrence.title}</dd></div>
          <div><dt>Task status</dt><dd>{occurrence.status.toLowerCase()}</dd></div>
          <div><dt>Due date</dt><dd>{formatHabitDate(day.date)}</dd></div>
          {occurrence.completedAt && <div><dt>Completed at</dt><dd>{formatHabitTimestamp(occurrence.completedAt, timezone)}</dd></div>}
          {occurrence.closedAt && <div><dt>Closed at</dt><dd>{formatHabitTimestamp(occurrence.closedAt, timezone)}</dd></div>}
        </dl>
        {day.state === "NOT_DAILY" && <p>This saved task used a different cadence and does not count as a daily habit result.</p>}
        <p>Timestamps shown in {timezone}. Results belong to the due date, not the submission date.</p>
      </> : <p>No saved occurrence for this day.</p>}
    </section>
  );
}
