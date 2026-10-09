import { AppError } from "../../shared/app_error.js";
import { dateInTimeZone } from "../tasks/recurrence.js";
import { buildReportMetrics, outcomeCounts } from "./report_metrics.js";
import { reportRepository, reportSnapshot } from "./report_repository.js";

export const reportService = {
  async get(userId: number, workspaceId: number, requestedYear?: number) {
    return reportSnapshot(async (db) => {
      const preference = await reportRepository.preference(db, userId);
      if (!preference) throw new AppError("PREFERENCES_NOT_FOUND", "User preferences not found", 404);
      const now = new Date();
      const asOfDate = dateInTimeZone(now, preference.timezone);
      const year = requestedYear ?? Number(asOfDate.slice(0, 4));
      const [tasks, projects, inventory, overdue, undated] = await Promise.all([
        reportRepository.tasks(db, workspaceId, year), reportRepository.projects(db, workspaceId),
        reportRepository.inventory(db, workspaceId), reportRepository.overdue(db, workspaceId, asOfDate),
        reportRepository.undated(db, workspaceId),
      ]);
      const countsFor = (projectId: number | null) => outcomeCounts(inventory.filter((row) => row.projectId === projectId)
        .map((row) => ({ status: row.status, count: row._count._all })));
      const projectItems = projects.map((project) => ({ ...project, ...countsFor(project.id) }))
        .sort((a, b) => b.total - a.total || a.id - b.id);
      return {
        generatedAt: now.toISOString(), asOfDate, timezone: preference.timezone, year,
        scope: { dueFrom: `${year}-01-01`, dueTo: `${year}-12-31`, basis: "saved_occurrences" },
        ...buildReportMetrics(tasks, year, preference.timezone, asOfDate),
        currentInventory: { ...outcomeCounts(inventory.map((row) => ({ status: row.status, count: row._count._all }))), overdue, undated },
        projects: { items: projectItems.slice(0, 20), totalProjects: projects.length, limit: 20, unassigned: countsFor(null) },
      };
    });
  },
};
