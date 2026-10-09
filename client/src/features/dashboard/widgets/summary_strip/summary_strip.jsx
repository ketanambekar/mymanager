import { CalendarDays, CircleCheck, ClockAlert, Hourglass } from "lucide-react";
import "./summary_strip.css";

export default function SummaryStrip({ className = "", completedCount, completedTodayCount, completionRate, dueTodayCount, overdueCount, pendingTodayCount, skippedCount, totalCount }) {

  return (
    <div aria-label="Task summary" className={["summary-strip", className].filter(Boolean).join(" ")} role="group" tabIndex={0}>
      <div aria-label={`${overdueCount} overdue tasks`} className="summary-metric summary-metric--overdue">
        <span className="summary-metric-label"><ClockAlert aria-hidden="true" size={16} />Overdue</span>
        <strong>{overdueCount}</strong>
      </div>
      <div aria-label={`${dueTodayCount} tasks scheduled today`} className="summary-metric summary-metric--today">
        <span className="summary-metric-label"><CalendarDays aria-hidden="true" size={16} />Due today</span>
        <strong>{dueTodayCount}</strong>
      </div>
      <div aria-label={`${pendingTodayCount} tasks still pending today`} className="summary-metric summary-metric--pending">
        <span className="summary-metric-label"><Hourglass aria-hidden="true" size={16} />Pending today</span>
        <strong>{pendingTodayCount}</strong>
      </div>
      <div aria-label={`${completedTodayCount} tasks completed today`} className="summary-metric summary-metric--finished">
        <span className="summary-metric-label"><CircleCheck aria-hidden="true" size={16} />Done today</span>
        <strong>{completedTodayCount}</strong>
      </div>
      <div aria-label={`${completionRate}% complete, ${completedCount} of ${Math.max(totalCount - skippedCount, 0)} counted tasks`} className="completion-card">
        <div className="completion-heading">
          <span>Completion</span><strong>{completionRate}%</strong>
        </div>
        <div className="completion-details">
          <progress aria-label="Task completion" max={100} value={completionRate} />
          <span>{completedCount} / {Math.max(totalCount - skippedCount, 0)} done</span>
        </div>
      </div>
    </div>
  );
}
