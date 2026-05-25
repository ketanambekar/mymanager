"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, PencilLine, Plus, Trash2 } from "lucide-react";
import { Sidebar, SidebarSection } from "@/components/dashboard/sidebar";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useDashboardStore } from "@/store/dashboard-store";
import {
  createSubTask,
  createTask,
  deleteProject,
  deleteTask,
  loadDashboardSnapshot,
  loadMasterCollections,
  loadProjectDetails,
  updateProject,
  updateTask,
} from "@/lib/dashboard-api";
import type { MasterCollections, ProjectDetail, TaskDetail, TaskStatus } from "@/types/dashboard";

type ProjectDetailsPageProps = {
  projectId: number;
};

type ProjectFormState = {
  name: string;
  description: string;
  typeId: string;
  colorId: string;
  priorityId: string;
  status: ProjectDetail["status"];
};

type TaskFormState = {
  name: string;
  description: string;
  priorityId: string;
  status: TaskStatus;
};

type SubTaskFormState = {
  name: string;
  description: string;
  status: TaskStatus;
};

function blankProjectForm(): ProjectFormState {
  return {
    name: "",
    description: "",
    typeId: "",
    colorId: "",
    priorityId: "",
    status: "ACTIVE",
  };
}

function blankTaskForm(): TaskFormState {
  return {
    name: "",
    description: "",
    priorityId: "",
    status: "PENDING",
  };
}

function blankSubTaskForm(): SubTaskFormState {
  return {
    name: "",
    description: "",
    status: "PENDING",
  };
}

function formatDateTime(value: string | null): string {
  if (!value) {
    return "Not set";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "Not set";
  }

  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}

export function ProjectDetailsPage({ projectId }: ProjectDetailsPageProps) {
  const router = useRouter();
  const { projects, loadDashboard } = useDashboardStore();
  const [masters, setMasters] = useState<MasterCollections | null>(null);
  const [project, setProject] = useState<ProjectDetail | null>(null);
  const [tasks, setTasks] = useState<TaskDetail[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSavingProject, setIsSavingProject] = useState(false);
  const [isSavingTask, setIsSavingTask] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [projectForm, setProjectForm] = useState<ProjectFormState>(blankProjectForm());
  const [taskForm, setTaskForm] = useState<TaskFormState>(blankTaskForm());
  const [editingTaskId, setEditingTaskId] = useState<number | null>(null);
  const [subTaskForms, setSubTaskForms] = useState<Record<number, SubTaskFormState>>({});

  useEffect(() => {
    void loadDashboard();
  }, [loadDashboard]);

  async function refreshProject() {
    setIsLoading(true);
    setError(null);

    try {
      const [snapshot, masterCollections, detail] = await Promise.all([
        loadDashboardSnapshot(),
        loadMasterCollections(),
        loadProjectDetails(projectId),
      ]);

      setMasters(masterCollections);
      setProject(detail.project);
      setTasks(detail.tasks);
      setProjectForm({
        name: detail.project.name,
        description: detail.project.description ?? "",
        typeId: String(detail.project.typeId),
        colorId: String(detail.project.colorId),
        priorityId: String(detail.project.priorityId),
        status: detail.project.status,
      });
      setTaskForm(blankTaskForm());
      setEditingTaskId(null);
      setSubTaskForms({});

      if (!snapshot.projects.length) {
        void loadDashboard();
      }
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : "Unable to load project details.");
      setProject(null);
      setTasks([]);
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    void refreshProject();
  }, [projectId]);

  const sidebarSection: SidebarSection = "projects";
  const taskSummary = useMemo(() => {
    const statusCounts = tasks.reduce<Record<string, number>>((counts, task) => {
      counts[task.status] = (counts[task.status] ?? 0) + 1;
      return counts;
    }, {});

    return {
      total: tasks.length,
      active: statusCounts.ACTIVE ?? 0,
      completed: statusCounts.COMPLETED ?? 0,
    };
  }, [tasks]);
  const selectedProjectPriority = masters?.priorities.find((priority) => String(priority.id) === projectForm.priorityId);
  const selectedTaskPriority = masters?.priorities.find((priority) => String(priority.id) === taskForm.priorityId);

  function handleSidebarSelect(section: SidebarSection) {
    if (section === "projects") {
      return;
    }

    router.push("/");
  }

  async function handleProjectSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!project) {
      return;
    }

    setIsSavingProject(true);
    setError(null);

    try {
      await updateProject(projectId, {
        name: projectForm.name.trim(),
        description: projectForm.description.trim() || null,
        typeId: Number(projectForm.typeId),
        colorId: Number(projectForm.colorId),
        priorityId: Number(projectForm.priorityId),
        status: projectForm.status,
      });
      await refreshProject();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : "Unable to update project.");
    } finally {
      setIsSavingProject(false);
    }
  }

  async function handleDeleteProject() {
    if (!project) {
      return;
    }

    const confirmed = window.confirm(`Delete ${project.name}? This will archive the project in the backend.`);
    if (!confirmed) {
      return;
    }

    setIsSavingProject(true);
    setError(null);

    try {
      await deleteProject(projectId);
      router.push("/projects");
    } catch (deleteError) {
      setError(deleteError instanceof Error ? deleteError.message : "Unable to delete project.");
      setIsSavingProject(false);
    }
  }

  function startEditTask(task: TaskDetail) {
    setEditingTaskId(task.id);
    setTaskForm({
      name: task.name,
      description: task.description ?? "",
      priorityId: String(task.priorityId),
      status: task.status,
    });
  }

  function cancelTaskEdit() {
    setEditingTaskId(null);
    setTaskForm(blankTaskForm());
  }

  async function handleTaskSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!project) {
      return;
    }

    if (!taskForm.name.trim() || !taskForm.priorityId) {
      return;
    }

    setIsSavingTask(true);
    setError(null);

    const payload = {
      projectId: project.id,
      name: taskForm.name.trim(),
      description: taskForm.description.trim() || undefined,
      priorityId: Number(taskForm.priorityId),
      status: taskForm.status,
    };

    try {
      if (editingTaskId) {
        await updateTask(editingTaskId, payload);
      } else {
        await createTask(payload);
      }

      await refreshProject();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : "Unable to save task.");
    } finally {
      setIsSavingTask(false);
    }
  }

  function getSubTaskForm(taskId: number): SubTaskFormState {
    return subTaskForms[taskId] ?? blankSubTaskForm();
  }

  function updateSubTaskForm(taskId: number, patch: Partial<SubTaskFormState>) {
    setSubTaskForms((current) => ({
      ...current,
      [taskId]: {
        ...(current[taskId] ?? blankSubTaskForm()),
        ...patch,
      },
    }));
  }

  async function handleCreateSubTask(taskId: number) {
    const draft = getSubTaskForm(taskId);

    if (!draft.name.trim()) {
      return;
    }

    setIsSavingTask(true);
    setError(null);

    try {
      await createSubTask({
        taskId,
        name: draft.name,
        description: draft.description,
        status: draft.status,
      });

      setSubTaskForms((current) => ({
        ...current,
        [taskId]: blankSubTaskForm(),
      }));
      await refreshProject();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : "Unable to add subtask.");
    } finally {
      setIsSavingTask(false);
    }
  }

  async function handleDeleteTask(taskId: number) {
    const confirmed = window.confirm("Delete this task?");
    if (!confirmed) {
      return;
    }

    setIsSavingTask(true);
    setError(null);

    try {
      await deleteTask(taskId);
      if (editingTaskId === taskId) {
        cancelTaskEdit();
      }
      await refreshProject();
    } catch (deleteError) {
      setError(deleteError instanceof Error ? deleteError.message : "Unable to delete task.");
    } finally {
      setIsSavingTask(false);
    }
  }

  return (
    <div className="grain-layer min-h-screen px-3 py-4 text-[var(--ink)] sm:px-4 lg:px-6">
      <div className="relative mx-auto flex w-full max-w-none flex-col gap-4 lg:flex-row lg:items-start">
        <div className="w-full lg:w-[220px] lg:flex-none">
          <Sidebar
            activeSection={sidebarSection}
            onSelect={handleSidebarSelect}
            projects={projects}
            selectedProjectId={projectId}
            onOpenProjects={() => router.push("/projects")}
            onOpenProject={(nextProjectId) => router.push(`/projects/${nextProjectId}`)}
          />
        </div>

        <main className="min-w-0 flex-1 space-y-4">
          <header className="enter-rise rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4">
            <div className="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
              <div className="min-w-0 max-w-2xl">
                <div className="mb-2 inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1 text-[11px] uppercase tracking-[0.14em] text-[var(--muted)]">
                  Project details
                </div>
                <h1 className="text-[1.6rem] font-extrabold sm:text-[2.2rem]">{project?.name ?? "Loading project..."}</h1>
                <p className="mt-1 max-w-xl text-sm leading-6 text-[var(--muted)]">
                  Edit the project, manage related tasks, and keep everything in one place.
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-2 xl:justify-end">
                <div className="rounded-full border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1.5 text-xs text-[var(--muted)]">
                  {taskSummary.total} tasks • {taskSummary.active} active • {taskSummary.completed} done
                </div>
                <Button variant="secondary" onClick={() => router.push("/projects") }>
                  <ArrowLeft className="mr-1.5 h-4 w-4" /> Back to projects
                </Button>
              </div>
            </div>
          </header>

          {error ? (
            <div className="rounded-md border border-[color:var(--danger)]/60 bg-[#3d1f1b] px-3 py-2.5 text-sm text-[#ffb0a2]">
              {error}
            </div>
          ) : null}

          {isLoading && !project ? (
            <div className="rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4 text-sm text-[var(--muted)]">
              Loading project details...
            </div>
          ) : null}

          {project ? (
            <>
              <Card className="rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4">
                <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h2 className="text-lg font-extrabold">Project CRUD</h2>
                    <p className="text-xs text-[var(--muted)]">Update the project or delete it when it is finished.</p>
                  </div>
                  <Button type="button" variant="secondary" onClick={handleDeleteProject} disabled={isSavingProject}>
                    <Trash2 className="mr-1.5 h-4 w-4" /> Delete project
                  </Button>
                </div>

                <form onSubmit={handleProjectSubmit} className="grid gap-3 md:grid-cols-2">
                  <label className="grid gap-1 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Name</span>
                    <input
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={projectForm.name}
                      onChange={(event) => setProjectForm((current) => ({ ...current, name: event.target.value }))}
                    />
                  </label>

                  <label className="grid gap-1 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Description</span>
                    <textarea
                      className="min-h-24 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-2 outline-none focus:border-[var(--brand-orange)]"
                      value={projectForm.description}
                      onChange={(event) => setProjectForm((current) => ({ ...current, description: event.target.value }))}
                    />
                  </label>

                  <label className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Type</span>
                    <select
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={projectForm.typeId}
                      onChange={(event) => setProjectForm((current) => ({ ...current, typeId: event.target.value }))}
                    >
                      <option value="">Choose type</option>
                      {masters?.projectTypes.map((type) => (
                        <option key={type.id} value={type.id}>
                          {type.label}
                        </option>
                      ))}
                    </select>
                  </label>

                  <div className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Priority</span>
                    <div className="flex flex-wrap gap-2">
                      {masters?.priorities.map((priority) => {
                        const isSelected = String(priority.id) === projectForm.priorityId;

                        return (
                          <button
                            key={priority.id}
                            type="button"
                            onClick={() => setProjectForm((current) => ({ ...current, priorityId: String(priority.id) }))}
                            className={
                              isSelected
                                ? "rounded-md border border-[var(--brand-orange)] bg-[var(--surface)] px-3 py-1.5 text-xs font-semibold text-[var(--ink)]"
                                : "rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1.5 text-xs font-semibold text-[var(--muted)] hover:border-[var(--border-strong)] hover:text-[var(--ink)]"
                            }
                          >
                            {priority.code}
                          </button>
                        );
                      })}
                    </div>
                    <p className="text-xs text-[var(--muted)]">
                      {selectedProjectPriority
                        ? `Selected: ${selectedProjectPriority.code} - ${selectedProjectPriority.title}`
                        : "Select one priority flag"}
                    </p>
                  </div>

                  <label className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Color</span>
                    <select
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={projectForm.colorId}
                      onChange={(event) => setProjectForm((current) => ({ ...current, colorId: event.target.value }))}
                    >
                      <option value="">Choose color</option>
                      {masters?.colors.map((color) => (
                        <option key={color.id} value={color.id}>
                          {color.label}
                        </option>
                      ))}
                    </select>
                  </label>

                  <label className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Status</span>
                    <select
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={projectForm.status}
                      onChange={(event) => setProjectForm((current) => ({ ...current, status: event.target.value as ProjectDetail["status"] }))}
                    >
                      <option value="ACTIVE">Active</option>
                      <option value="HOLD">Hold</option>
                      <option value="COMPLETED">Completed</option>
                      <option value="ARCHIVED">Archived</option>
                    </select>
                  </label>

                  <div className="md:col-span-2 flex justify-end">
                    <Button type="submit" disabled={isSavingProject || !masters}>
                      Save project
                    </Button>
                  </div>
                </form>
              </Card>

              <Card className="rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4">
                <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h2 className="text-lg font-extrabold">Task CRUD</h2>
                    <p className="text-xs text-[var(--muted)]">Create a task, edit it in place, or remove it entirely.</p>
                  </div>
                  {editingTaskId ? (
                    <Button type="button" variant="secondary" onClick={cancelTaskEdit}>
                      Cancel edit
                    </Button>
                  ) : null}
                </div>

                <form onSubmit={handleTaskSubmit} className="grid gap-3 md:grid-cols-2">
                  <label className="grid gap-1 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Name</span>
                    <input
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={taskForm.name}
                      onChange={(event) => setTaskForm((current) => ({ ...current, name: event.target.value }))}
                    />
                  </label>

                  <label className="grid gap-1 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Description</span>
                    <textarea
                      className="min-h-20 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-2 outline-none focus:border-[var(--brand-orange)]"
                      value={taskForm.description}
                      onChange={(event) => setTaskForm((current) => ({ ...current, description: event.target.value }))}
                    />
                  </label>

                  <div className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Priority</span>
                    <div className="flex flex-wrap gap-2">
                      {masters?.priorities.map((priority) => {
                        const isSelected = String(priority.id) === taskForm.priorityId;

                        return (
                          <button
                            key={priority.id}
                            type="button"
                            onClick={() => setTaskForm((current) => ({ ...current, priorityId: String(priority.id) }))}
                            className={
                              isSelected
                                ? "rounded-md border border-[var(--brand-orange)] bg-[var(--surface)] px-3 py-1.5 text-xs font-semibold text-[var(--ink)]"
                                : "rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1.5 text-xs font-semibold text-[var(--muted)] hover:border-[var(--border-strong)] hover:text-[var(--ink)]"
                            }
                          >
                            {priority.code}
                          </button>
                        );
                      })}
                    </div>
                    <p className="text-xs text-[var(--muted)]">
                      {selectedTaskPriority ? `Selected: ${selectedTaskPriority.code} - ${selectedTaskPriority.title}` : "Select one priority flag"}
                    </p>
                  </div>

                  <label className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Status</span>
                    <select
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={taskForm.status}
                      onChange={(event) => setTaskForm((current) => ({ ...current, status: event.target.value as TaskStatus }))}
                    >
                      <option value="PENDING">Pending</option>
                      <option value="ACTIVE">Active</option>
                      <option value="IN_PROGRESS">In Progress</option>
                      <option value="IN_REVIEW">In Review</option>
                      <option value="HOLD">Hold</option>
                      <option value="COMPLETED">Completed</option>
                    </select>
                  </label>

                  <div className="md:col-span-2 flex justify-end">
                    <Button type="submit" disabled={isSavingTask || !masters}>
                      {editingTaskId ? (
                        <>
                          <PencilLine className="mr-1.5 h-4 w-4" /> Update task
                        </>
                      ) : (
                        <>
                          <Plus className="mr-1.5 h-4 w-4" /> Create task
                        </>
                      )}
                    </Button>
                  </div>
                </form>

                <div className="mt-4 space-y-2">
                  {tasks.map((task) => (
                    <div key={task.id} className="rounded-xl border border-[var(--border)] bg-[var(--surface-muted)] p-3">
                      {(() => {
                        const subTaskForm = getSubTaskForm(task.id);

                        return (
                          <>
                            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                              <div className="min-w-0">
                                <p className="text-sm font-semibold text-[var(--ink)]">{task.name}</p>
                                <p className="mt-0.5 text-xs text-[var(--muted)]">{task.description ?? "No description yet."}</p>
                              </div>

                              <div className="flex flex-wrap items-center gap-2">
                                <Button type="button" variant="secondary" onClick={() => startEditTask(task)}>
                                  <PencilLine className="mr-1.5 h-4 w-4" /> Edit
                                </Button>
                                <Button type="button" variant="secondary" onClick={() => handleDeleteTask(task.id)} disabled={isSavingTask}>
                                  <Trash2 className="mr-1.5 h-4 w-4" /> Delete
                                </Button>
                              </div>
                            </div>

                            <div className="mt-3 flex flex-wrap gap-2 text-xs text-[var(--muted)]">
                              <span className="rounded-full border border-[var(--border)] bg-[var(--surface)] px-2.5 py-1">
                                Status: {task.status.replace("_", " ")}
                              </span>
                              <span className="rounded-full border border-[var(--border)] bg-[var(--surface)] px-2.5 py-1">
                                Priority: {task.priority.code} - {task.priority.title}
                              </span>
                              <span className="rounded-full border border-[var(--border)] bg-[var(--surface)] px-2.5 py-1">
                                Subtasks: {task.subtasks.length}
                              </span>
                              <span className="rounded-full border border-[var(--border)] bg-[var(--surface)] px-2.5 py-1">
                                Updated {formatDateTime(task.updatedAt)}
                              </span>
                            </div>

                            <div className="mt-3 rounded-lg border border-[var(--border)] bg-[var(--surface)] p-3">
                              <p className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Add subtask</p>
                              <div className="mt-2 grid gap-2 md:grid-cols-[minmax(0,1fr),180px,auto]">
                                <input
                                  value={subTaskForm.name}
                                  onChange={(event) => updateSubTaskForm(task.id, { name: event.target.value })}
                                  placeholder="Subtask name"
                                  className="h-9 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 text-sm outline-none focus:border-[var(--brand-orange)]"
                                />
                                <select
                                  value={subTaskForm.status}
                                  onChange={(event) => updateSubTaskForm(task.id, { status: event.target.value as TaskStatus })}
                                  className="h-9 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 text-sm outline-none focus:border-[var(--brand-orange)]"
                                >
                                  <option value="PENDING">Pending</option>
                                  <option value="ACTIVE">Active</option>
                                  <option value="IN_PROGRESS">In Progress</option>
                                  <option value="IN_REVIEW">In Review</option>
                                  <option value="HOLD">Hold</option>
                                  <option value="COMPLETED">Completed</option>
                                </select>
                                <Button
                                  type="button"
                                  onClick={() => handleCreateSubTask(task.id)}
                                  disabled={isSavingTask || !subTaskForm.name.trim()}
                                >
                                  <Plus className="mr-1.5 h-4 w-4" /> Add
                                </Button>
                              </div>
                              <textarea
                                value={subTaskForm.description}
                                onChange={(event) => updateSubTaskForm(task.id, { description: event.target.value })}
                                placeholder="Description (optional)"
                                className="mt-2 min-h-16 w-full rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-2 text-sm outline-none focus:border-[var(--brand-orange)]"
                              />
                            </div>

                            {task.subtasks.length ? (
                              <div className="mt-3 rounded-lg border border-[var(--border)] bg-[var(--surface)] p-3">
                                <p className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Subtasks</p>
                                <div className="mt-2 space-y-1 text-sm text-[var(--ink)]">
                                  {task.subtasks.map((subtask) => (
                                    <div key={subtask.id} className="flex items-center justify-between gap-2">
                                      <span className="truncate">{subtask.name}</span>
                                      <span className="shrink-0 text-xs text-[var(--muted)]">{subtask.status.replace("_", " ")}</span>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            ) : null}
                          </>
                        );
                      })()}
                    </div>
                  ))}

                  {!tasks.length ? (
                    <div className="rounded-md border border-dashed border-[var(--border-strong)] bg-[var(--surface-muted)] p-4 text-sm text-[var(--muted)]">
                      No tasks have been added to this project yet.
                    </div>
                  ) : null}
                </div>
              </Card>
            </>
          ) : null}
        </main>
      </div>
    </div>
  );
}
