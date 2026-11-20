import { getRecurrenceLabel } from "@/features/dashboard/task_recurrence.js";
import { reportRate } from "@/features/reports/report_utils.js";
import "./report_rankings.css";

export default function ReportRankings({ report }) {
  const { habits, reasons, recurringSummary: recurring } = report;
  return (
    <div className="report-rankings">
      <section className="report-panel" aria-labelledby="report-recurring-heading">
        <h2 id="report-recurring-heading">Recurring results</h2>
        <p className="report-scope">SELECTED-YEAR DUE OUTCOMES · {report.year}. All recurring cadences; no expected-period or streak assumptions.</p>
        <div className="report-recurring-summary"><strong>{recurring.total} occurrences</strong><span>{recurring.seriesCount} series · {reportRate(recurring.completionRate)}</span><span>Completed {recurring.completed} · Skipped {recurring.skipped} · Missed {recurring.missed} · Open {recurring.open}</span></div>
        <p className="report-ranking-limit">Top {habits.limit} by completions · Showing {habits.items.length} of {habits.totalSeries} series</p>
        {habits.items.length ? <ol className="report-ranked-list">{habits.items.map((habit) => <li key={habit.id}><div className="report-ranked-title"><h3>{habit.title}</h3><span className="report-ranked-rate">{reportRate(habit.completionRate)}</span></div><p className="report-cadence">{getRecurrenceLabel(habit.recurrence)}</p><p className="report-ranked-counts">{habit.total} occurrences · Completed {habit.completed} · Skipped {habit.skipped} · Missed {habit.missed} · Open {habit.open}</p></li>)}</ol> : <p className="report-empty">No recurring due occurrences saved in this year.</p>}
        <p className="report-scope">Names and cadence reflect the representative occurrence within this due-year cohort, not necessarily the series' current settings.</p>
      </section>
      <section className="report-panel" aria-labelledby="report-reasons-heading">
        <h2 id="report-reasons-heading">Saved reasons</h2>
        <p className="report-scope">SELECTED-YEAR DUE OUTCOMES · {report.year}. Exact saved reasons, grouped by outcome; no interpretation or inferred causes.</p>
        <p className="report-ranking-limit">Top {reasons.limit} by count · Showing {reasons.items.length} of {reasons.totalReasons} reasons</p>
        {reasons.items.length ? <ol className="report-ranked-list report-reasons">{reasons.items.map((item) => <li key={JSON.stringify([item.status, item.reason])}><div className="report-ranked-title"><span className={`report-reason-status report-reason-status--${item.status.toLowerCase()}`}>{item.status === "SKIPPED" ? "Skipped" : "Missed"}</span><strong>{item.count} occurrences</strong></div><p>{item.reason}</p></li>)}</ol> : <p className="report-empty">No saved skip or miss reasons in this due-year cohort. Empty legacy reasons are not invented.</p>}
      </section>
    </div>
  );
}
