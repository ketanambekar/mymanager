import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { REPORT_OUTCOMES, REPORT_ACTIVITY } from "@/features/reports/constants/report_constants.js";
import { reportDate } from "@/features/reports/report_utils.js";
import "./report_trends.css";

function Trend({ monthly, year, activity }) {
  const fields = activity ? REPORT_ACTIVITY : REPORT_OUTCOMES;
  const rows = monthly.map((entry) => ({ month: reportDate(`${entry.month}-01`, { month: "short" }), ...(activity ? entry.activity : entry.due) }));
  return (
    <section className="report-panel report-trend" aria-labelledby={activity ? "report-actions-title" : "report-monthly-title"}>
      <h2 id={activity ? "report-actions-title" : "report-monthly-title"}>{activity ? "Actions recorded by month" : "Due outcomes by month"}</h2>
      <p className="report-scope">{activity ? `Completion/closure timestamps in ${year}, localized to your saved timezone. These actions may concern tasks due in another year.` : `Saved occurrences due in ${year}, grouped by due month. Empty months are not automatic misses.`}</p>
      <div className="report-chart">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={rows} accessibilityLayer>
            <CartesianGrid vertical={false} stroke="var(--line)" />
            <XAxis dataKey="month" tick={{ fill: "var(--muted)", fontSize: 10 }} tickLine={false} axisLine={false} interval="preserveStartEnd" />
            <YAxis allowDecimals={false} width={32} tick={{ fill: "var(--muted)", fontSize: 10 }} tickLine={false} axisLine={false} />
            <Tooltip contentStyle={{ background: "var(--surface-raised)", color: "var(--ink)", border: "1px solid var(--line)", borderRadius: 8 }} cursor={{ fill: "var(--surface-hover)" }} />
            {fields.map(({ key, label }) => <Bar dataKey={key} fill={`var(--report-${key})`} isAnimationActive={false} key={key} name={label} stackId="outcomes" maxBarSize={24} />)}
          </BarChart>
        </ResponsiveContainer>
      </div>
      <div className="report-legend">{fields.map(({ key, label }) => <span key={key}><i aria-hidden="true" className={`report-dot report-dot--${key}`} />{label}</span>)}</div>
      <details><summary>View monthly counts</summary><div className="report-table-wrap"><table className="report-table"><caption>{activity ? "Recorded timestamp activity" : "Due-date outcomes"} · {year}</caption><thead><tr><th scope="col">Month</th>{fields.map(({ key, label }) => <th key={key} scope="col">{label}</th>)}</tr></thead><tbody>{rows.map((row) => <tr key={row.month}><th scope="row">{row.month}</th>{fields.map(({ key }) => <td key={key}>{row[key]}</td>)}</tr>)}</tbody></table></div></details>
    </section>
  );
}

export default function ReportTrends({ monthly, year }) {
  return <div className="report-trends"><Trend monthly={monthly} year={year} /><Trend activity monthly={monthly} year={year} /></div>;
}
