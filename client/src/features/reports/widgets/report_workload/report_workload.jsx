import { reportRate } from "@/features/reports/report_utils.js";
import { REPORT_OUTCOMES } from "@/features/reports/constants/report_constants.js";
import "./report_workload.css";

export default function ReportWorkload({ report }) {
  const { currentInventory: inventory, projects } = report;
  return (
    <section className="report-panel" aria-labelledby="report-current-heading">
      <p className="report-section-eyebrow">CURRENT ALL-TIME SNAPSHOT · NOT YEAR-FILTERED</p>
      <h2 id="report-current-heading">Current workload &amp; projects</h2>
      <p className="report-scope">All saved tasks as of {report.asOfDate}, regardless of due year. Project counts are direct top-level task outcomes only: no subtasks or descendant rollups, unlike dashboard branch progress.</p>
      <dl className="report-inventory"><div><dt>Saved tasks</dt><dd>{inventory.total}</dd></div>{REPORT_OUTCOMES.map(({ key, label }) => <div key={key}><dt>{label}</dt><dd>{inventory[key]}</dd></div>)}<div><dt>Overdue open</dt><dd>{inventory.overdue}</dd></div><div><dt>Undated</dt><dd>{inventory.undated}</dd></div><div><dt>Completion rate</dt><dd className="report-inventory-rate">{reportRate(inventory.completionRate)}</dd></div></dl>
      <h3 className="report-project-heading">Current direct task outcomes</h3>
      <p className="report-ranking-limit">Top {projects.limit} by direct task count · Showing {projects.items.length} of {projects.totalProjects} projects</p>
      {projects.items.length > 0 ? <div className="report-project-grid">{projects.items.map((project) => {
        const parent = projects.items.find((item) => item.id === project.parentProjectId);
        return <article className="report-project-card" key={project.id}><h4>{project.name}</h4><p className="report-project-hierarchy">{project.parentProjectId ? `Subproject${parent ? ` of ${parent.name}` : " (parent outside ranked list)"}` : "Top-level project"}</p><div className="report-project-total"><strong>{project.total} direct tasks</strong><span>{reportRate(project.completionRate)}</span></div><p>Completed {project.completed} · Skipped {project.skipped} · Missed {project.missed} · Open {project.open}</p></article>;
      })}</div> : <p className="report-empty">No saved projects.</p>}
      <div className="report-unassigned"><h3>Unassigned direct tasks</h3><strong>{projects.unassigned.total} tasks · {reportRate(projects.unassigned.completionRate)}</strong><p>Completed {projects.unassigned.completed} · Skipped {projects.unassigned.skipped} · Missed {projects.unassigned.missed} · Open {projects.unassigned.open}</p></div>
    </section>
  );
}
