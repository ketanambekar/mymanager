import { lazy, Suspense } from "react";
import { CalendarDays, CircleCheck, ClockAlert, Hourglass } from "lucide-react";
import "./summary_strip.css";

const TaskCompletionChart = lazy(() => import("../task_completion_chart/task_completion_chart.jsx"));

export default function SummaryStrip({ completedCount, completedTodayCount, completionRate, dueTodayCount, missedCount, openCount, overdueCount, pendingTodayCount, skippedCount, totalCount }) {

  return (
    <div aria-label="Task summary" className="summary-strip" role="group">
      <div aria-label={`${overdueCount} overdue tasks`} className="summary-metric summary-metric--overdue">
        <span className="summary-metric-label"><ClockAlert aria-hidden="true" size={16} />OVERDUE</span>
        <strong>{overdueCount}</strong>
      </div>
      <div aria-label={`${dueTodayCount} tasks scheduled today`} className="summary-metric summary-metric--today">
        <span className="summary-metric-label"><CalendarDays aria-hidden="true" size={16} />DUE TODAY</span>
        <strong>{dueTodayCount}</strong>
      </div>
      <div aria-label={`${pendingTodayCount} tasks still pending today`} className="summary-metric summary-metric--pending">
        <span className="summary-metric-label"><Hourglass aria-hidden="true" size={16} />PENDING TODAY</span>
        <strong>{pendingTodayCount}</strong>
      </div>
      <div aria-label={`${completedTodayCount} tasks completed today`} className="summary-metric summary-metric--finished">
        <span className="summary-metric-label"><CircleCheck aria-hidden="true" size={16} />DONE TODAY</span>
        <strong>{completedTodayCount}</strong>
      </div>
      <div aria-label={`${completionRate}% complete, ${completedCount} of ${Math.max(totalCount - skippedCount, 0)} counted tasks`} className="completion-card">
        <Suspense fallback={<div aria-label="Loading completion chart" className="completion-chart chart-loading" role="status" />}>
          <TaskCompletionChart completedCount={completedCount} completionRate={completionRate} missedCount={missedCount} openCount={openCount} skippedCount={skippedCount} totalCount={totalCount} />
        </Suspense>
        <div className="completion-copy">
          <span>COMPLETION</span>
          <strong>{completedCount} <i>/ {Math.max(totalCount - skippedCount, 0)}</i></strong>
          <small>tasks finished</small>
        </div>
      </div>
    </div>
  );
}
