import { TaskStatus } from "@prisma/client";
import { prisma } from "../../database/prisma.js";
import { projectService } from "../projects/project_service.js";
import { dateInTimeZone } from "../tasks/recurrence.js";
import { taskInclude } from "../tasks/task_repository.js";
import { taskService, taskView } from "../tasks/task_service.js";

export const dashboardService = {
  async get(userId: number, workspaceId: number) {
    await taskService.materializeOverdue(userId, workspaceId);
    const preference = await prisma.userPreference.findUnique({ where: { userId } });
    const timezone = preference?.timezone ?? "UTC";
    const today = dateInTimeZone(new Date(), timezone);
    const [projects, tasks] = await Promise.all([
      projectService.list(workspaceId),
      prisma.task.findMany({ where: { workspaceId }, include: taskInclude, orderBy: [{ dueDate: "asc" }, { id: "desc" }] }),
    ]);
    const items = tasks.map(taskView);
    const countOf = (status: TaskStatus) => tasks.filter((task) => task.status === status).length;
    const completedCount = countOf(TaskStatus.COMPLETED);
    const openCount = countOf(TaskStatus.OPEN);
    const skippedCount = countOf(TaskStatus.SKIPPED);
    const missedCount = countOf(TaskStatus.MISSED);
    const ratedCount = tasks.length - skippedCount;
    const isOpen = (task: (typeof items)[number]) => task.status === TaskStatus.OPEN;
    const upcomingTasks = items.filter((task) => isOpen(task) && task.dueDate && task.dueDate > today);
    const recentTasks = items.filter((task) => !task.dueDate || task.dueDate <= today);
    return {
      asOfDate: today,
      timezone,
      summary: {
        totalCount: tasks.length,
        completedCount,
        openCount,
        skippedCount,
        missedCount,
        completionRate: ratedCount ? Math.round((completedCount / ratedCount) * 100) : 0,
        overdueCount: items.filter((task) => isOpen(task) && task.dueDate && task.dueDate < today).length,
        dueTodayCount: items.filter((task) => task.dueDate === today).length,
        pendingTodayCount: items.filter((task) => isOpen(task) && task.dueDate === today).length,
        completedTodayCount: tasks.filter((task) => task.status === TaskStatus.COMPLETED && task.completedAt && dateInTimeZone(task.completedAt, timezone) === today).length,
      },
      projects,
      recentTasks,
      upcomingTasks,
    };
  },
};