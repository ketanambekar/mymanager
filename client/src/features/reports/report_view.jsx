import { ArrowLeft, BarChart3, RefreshCw } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppSelect from "@/shared/widgets/app_select/app_select.jsx";
import AppFooter from "@/shared/widgets/app_footer/app_footer.jsx";
import { REPORT_YEARS } from "./constants/report_constants.js";
import { reportTimestamp } from "./report_utils.js";
import { useReportController } from "./use_report_controller.js";
import ReportOverview from "./widgets/report_overview/report_overview.jsx";
import ReportTrends from "./widgets/report_trends/report_trends.jsx";
import ReportActivity from "./widgets/report_activity/report_activity.jsx";
import ReportRankings from "./widgets/report_rankings/report_rankings.jsx";
import ReportWorkload from "./widgets/report_workload/report_workload.jsx";
import "./report_view.css";

export default function ReportView({ onBack }) {
  const controller = useReportController();
  const { report } = controller;
  return (
    <div className="reports-page">
      <header className="reports-header">
        <AppButton leadingIcon={<ArrowLeft aria-hidden="true" size={16} />} onClick={onBack} variant="secondary">Workspace</AppButton>
        <div className="reports-intro"><p>YOUR WORK, IN PERSPECTIVE</p><h1><BarChart3 aria-hidden="true" size={24} />Reports</h1><span>Saved outcomes. Recorded activity. A clearer picture.</span></div>
        <div className="reports-controls">
          <label>Report year<AppSelect onChange={(event) => controller.selectYear(event.target.value)} value={controller.year}>{controller.year === "" && <option disabled value="">Current year</option>}{REPORT_YEARS.map((year) => <option key={year} value={year}>{year}</option>)}</AppSelect></label>
          <AppButton disabled={controller.isLoading} leadingIcon={<RefreshCw aria-hidden="true" size={16} />} onClick={controller.refresh} variant="secondary">Refresh</AppButton>
        </div>
      </header>
      <main className="reports-content" aria-busy={controller.isLoading}>
        {controller.isLoading ? <div className="reports-state" role="status">Loading {controller.year || "your current-year"} report...</div> : controller.error ? <div className="reports-state" role="alert"><h2>Report unavailable</h2><p>{controller.error}</p><AppButton onClick={controller.refresh} variant="secondary">Retry report</AppButton></div> : report && <>
          <div className="reports-snapshot"><span>Year {report.year} · {report.timezone}</span><span>As of {report.asOfDate} · Updated {reportTimestamp(report.generatedAt, report.timezone)}</span></div>
          <ReportOverview report={report} />
          <ReportTrends monthly={report.monthly} year={report.year} />
          <ReportActivity report={report} />
          <ReportRankings report={report} />
          <ReportWorkload report={report} />
          <aside className="reports-quality"><h2>About these numbers</h2><p>Reports reflect current saved records, not an immutable event log. Reopening, editing or deleting tasks can change past results. Missing periods and days do not imply missed requirements or inactivity. No expected schedules, streaks or productivity scores are inferred.</p><p>Undated tasks are excluded from due-year outcomes but may appear in timestamp activity and always count in current workload. Refresh after changing your tasks.</p></aside>
        </>}
      </main>
      <AppFooter />
    </div>
  );
}
