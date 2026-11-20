import { activityCalendar, reportDate } from "@/features/reports/report_utils.js";
import "./report_activity.css";

export default function ReportActivity({ report }) {
  const months = activityCalendar(report.year, report.activityDays);
  return (
    <section className="report-panel" aria-labelledby="report-activity-heading">
      <h2 id="report-activity-heading">Recorded activity calendar</h2>
      <p className="report-scope">TIMESTAMP ACTIVITY · {report.year} · {report.timezone}. Current terminal outcomes with saved completion/closure timestamps, not every past action.</p>
      <div className="report-activity-summary"><span><strong>{report.activitySummary.completed}</strong> completed</span><span><strong>{report.activitySummary.skipped}</strong> skipped</span><span><strong>{report.activitySummary.missed}</strong> missed</span></div>
      {!report.activityDays.length && <p className="report-empty">No timestamp activity recorded in this year.</p>}
      <div className="report-heatmap">
        {months.map((month) => <section className="report-heatmap-month" key={month.month}><h3>{reportDate(`${month.month}-01`, { month: "long" })}</h3><div className="report-heatmap-days">
          {Array.from({ length: month.padding }, (_, index) => <span aria-hidden="true" key={`padding-${index}`} />)}
          {month.days.map((day) => {
            const label = `${day.date}: ${day.total ? `${day.activity.completed} completed, ${day.activity.skipped} skipped, ${day.activity.missed} missed` : "No recorded actions"}`;
            return <span aria-label={label} className={`report-heatmap-day report-heatmap-day--${day.level}`} key={day.date} role="img" title={label} />;
          })}
        </div></section>)}
      </div>
      <div className="report-heatmap-legend"><span>No recorded actions</span><i className="report-heatmap-day report-heatmap-day--0" /><i className="report-heatmap-day report-heatmap-day--1" /><span>1</span><i className="report-heatmap-day report-heatmap-day--2" /><span>2-3</span><i className="report-heatmap-day report-heatmap-day--3" /><span>4-6</span><i className="report-heatmap-day report-heatmap-day--4" /><span>7+</span></div>
      <p className="report-scope">Each month starts Monday-first. Blank days mean no recorded actions, not proof of inactivity.</p>
      {report.activityDays.length > 0 && <details><summary>View recorded dates and counts</summary><div className="report-table-wrap"><table className="report-table"><caption>Saved-timezone timestamp activity</caption><thead><tr><th scope="col">Date</th><th scope="col">Completed</th><th scope="col">Skipped</th><th scope="col">Missed</th></tr></thead><tbody>{report.activityDays.map((day) => <tr key={day.date}><th scope="row">{day.date}</th><td>{day.completed}</td><td>{day.skipped}</td><td>{day.missed}</td></tr>)}</tbody></table></div></details>}
    </section>
  );
}
