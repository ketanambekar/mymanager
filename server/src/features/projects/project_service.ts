import { Prisma, TaskStatus } from "@prisma/client";
import { prisma } from "../../database/prisma.js";
import { AppError } from "../../shared/app_error.js";
import { projectRepository } from "./project_repository.js";

type ProjectInput = { name: string; parentProjectId?: number | null; color: string };
type ProjectUpdate = Partial<ProjectInput> & { version: number };

async function validateParent(workspaceId: number, parentProjectId: number | null | undefined, projectId?: number) {
  if (!parentProjectId) return;
  const projects = await prisma.project.findMany({ where: { workspaceId }, select: { id: true, parentProjectId: true } });
  if (!projects.some((project) => project.id === parentProjectId)) throw new AppError("PROJECT_PARENT_INVALID", "Parent project not found", 400);
  let current: number | null = parentProjectId;
  const seen = new Set<number>();
  while (current) {
    if (current === projectId || seen.has(current)) throw new AppError("PROJECT_CYCLE", "A project cannot be moved below itself", 409);
    seen.add(current);
    current = projects.find((project) => project.id === current)?.parentProjectId ?? null;
  }
}

function projectStats(projects: Awaited<ReturnType<typeof projectRepository.list>>) {
  const children = new Map<number, number[]>();
  for (const project of projects) {
    if (project.parentProjectId) children.set(project.parentProjectId, [...(children.get(project.parentProjectId) ?? []), project.id]);
  }
  const descendants = (id: number): number[] => (children.get(id) ?? []).flatMap((childId) => [childId, ...descendants(childId)]);
  return projects.map((project) => {
    const branch = new Set([project.id, ...descendants(project.id)]);
    const tasks = projects.filter((candidate) => branch.has(candidate.id)).flatMap((candidate) => candidate.tasks).filter((task) => task.status !== TaskStatus.SKIPPED);
    const taskCount = tasks.reduce((count, task) => count + 1 + task.subtasks.length, 0);
    const completedCount = tasks.reduce((count, task) => count + Number(task.status === TaskStatus.COMPLETED) + task.subtasks.filter((subtask) => subtask.status === TaskStatus.COMPLETED).length, 0);
    const { tasks: _tasks, ...view } = project;
    return { ...view, subprojectCount: children.get(project.id)?.length ?? 0, taskCount, completedCount, progress: taskCount ? Math.round((completedCount / taskCount) * 100) : 0 };
  });
}

export const projectService = {
  async list(workspaceId: number) {
    return projectStats(await projectRepository.list(workspaceId));
  },
  async get(workspaceId: number, id: number) {
    const project = (await this.list(workspaceId)).find((candidate) => candidate.id === id);
    if (!project) throw new AppError("PROJECT_NOT_FOUND", "Project not found", 404);
    return project;
  },
  async create(workspaceId: number, input: ProjectInput) {
    await validateParent(workspaceId, input.parentProjectId);
    try {
      return await prisma.project.create({ data: { workspaceId, name: input.name, parentProjectId: input.parentProjectId ?? null, color: input.color } });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") throw new AppError("PROJECT_COLOR_TAKEN", "Choose an unused project color", 409);
      throw error;
    }
  },
  async update(workspaceId: number, id: number, input: ProjectUpdate) {
    const current = await projectRepository.find(workspaceId, id);
    if (!current) throw new AppError("PROJECT_NOT_FOUND", "Project not found", 404);
    if (current.version !== input.version) throw new AppError("VERSION_CONFLICT", "Project changed since it was loaded", 409);
    await validateParent(workspaceId, input.parentProjectId, id);
    const { version, ...data } = input;
    const result = await prisma.project.updateMany({ where: { id, workspaceId, version }, data: { ...data, version: { increment: 1 } } });
    if (!result.count) throw new AppError("VERSION_CONFLICT", "Project changed since it was loaded", 409);
    return projectRepository.find(workspaceId, id);
  },
  async remove(workspaceId: number, id: number) {
    const project = await projectRepository.find(workspaceId, id);
    if (!project) throw new AppError("PROJECT_NOT_FOUND", "Project not found", 404);
    await prisma.$transaction(async (transaction) => {
      await transaction.project.updateMany({ where: { workspaceId, parentProjectId: id }, data: { parentProjectId: project.parentProjectId } });
      await transaction.task.updateMany({ where: { workspaceId, projectId: id }, data: { projectId: project.parentProjectId } });
      await transaction.project.delete({ where: { id } });
    });
    return { id, reassignedProjectId: project.parentProjectId };
  },
};