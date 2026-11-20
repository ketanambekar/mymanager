import { CheckCircle2, SkipForward, CircleX, CircleDashed } from "lucide-react";
import { REPORT_OUTCOMES } from "@/features/reports/constants/report_constants.js";
import { reportRate } from "@/features/reports/report_utils.js";
import "./report_overview.css";

const outcomeIcons = { completed: CheckCircle2, skipped: SkipForward, missed: CircleX, open: CircleDashed };

export default function ReportOverview({ report }) {
  const due = report.dueSummary;
  return (
    <section className="report-panel report-overview" aria-labelledby="report-due-heading">
      <div className="report-overview-heading"><div><p className="report-section-eyebrow">SELECTED-YEAR DUE OUTCOMES</p><h2 id="report-due-heading">{report.year}, by due date</h2></div><span className="report-total">{due.total} saved occurrences</span></div>
      <p className="report-scope">{report.scope.dueFrom} to {report.scope.dueTo}. Includes future saved occurrences; this is a current cohort snapshot, not a final historical success rate.</p>
      <dl className="report-kpis">
        {REPORT_OUTCOMES.map(({ key, label }) => {
          const Icon = outcomeIcons[key];
          return <div className={`report-kpi report-kpi--${key}`} key={key}><dt><Icon aria-hidden="true" size={16} />{label}</dt><dd>{due[key]}</dd></div>;
        })}
        <div className="report-kpi"><dt>Completion rate</dt><dd className={due.completionRate === null ? "report-no-rate" : ""}>{reportRate(due.completionRate)}</dd><small>{due.rated} rated · skipped excluded</small></div>
        <div className="report-kpi"><dt>On-time rate</dt><dd className={due.onTimeRate === null ? "report-no-rate" : ""}>{reportRate(due.onTimeRate)}</dd><small>Known completion timestamps only</small></div>
      </dl>
      {due.total > 0 ? <><div className="report-distribution" role="img" aria-label={REPORT_OUTCOMES.map(({ key, label }) => `${label}: ${due[key]}`).join(", ")}>{REPORT_OUTCOMES.filter(({ key }) => due[key] > 0).map(({ key }) => <span className={`report-distribution--${key}`} key={key} style={{ flexGrow: due[key] }} />)}</div><div className="report-legend">{REPORT_OUTCOMES.map(({ key, label }) => <span key={key}><i aria-hidden="true" className={`report-dot report-dot--${key}`} />{label} {due[key]}</span>)}</div></> : <p className="report-empty">No saved due history for {report.year}. Timestamp activity and current workload may still contain records.</p>}
      <div className="report-timing"><span><strong>{due.overdue}</strong> overdue open</span><span><strong>{due.onTimeCompleted}</strong> completed on time</span><span><strong>{due.lateCompleted}</strong> completed late</span><span><strong>{due.completionTimingUnknown}</strong> completion timing unknown</span></div>
    </section>
  );
}
