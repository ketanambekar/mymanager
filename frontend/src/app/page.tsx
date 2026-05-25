"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { CalendarDays, Crosshair, Plus, Search, SlidersHorizontal } from "lucide-react";
import { useRouter } from "next/navigation";
import { MastersTabs } from "@/components/dashboard/masters-tabs";
import { Sidebar, SidebarSection } from "@/components/dashboard/sidebar";
import { TaskList } from "@/components/dashboard/task-list";
import { Button } from "@/components/ui/button";
import { createSubTask, deleteSubTask, updateSubTask, updateTask } from "@/lib/dashboard-api";
import { useDashboardStore } from "@/store/dashboard-store";
import { TaskItem, TaskStatus } from "@/types/dashboard";

export default function Home() {
  const router = useRouter();
  const {
    projects,
    tasks,
    masters,
    loadDashboard,
    loadMasters,
    submitProject,
    submitTask,
    createProjectTypeMaster,
    updateProjectTypeMaster,
    createPriorityMaster,
    updatePriorityMaster,
    createProjectColorMaster,
    updateProjectColorMaster,
    deleteProjectColorMaster,
    setTaskStatus,
    openComposer,
    closeComposer,
    isComposerOpen,
    openProjectComposer,
    closeProjectComposer,
    isProjectComposerOpen,
    isLoading,
    error,
    activePanel,
    setActivePanel,
    selectedProjectId,
    setSelectedProjectId,
  } = useDashboardStore();
  const [taskName, setTaskName] = useState("");
  const [taskDescription, setTaskDescription] = useState("");
  const [taskProjectId, setTaskProjectId] = useState<number | "">("");
  const [taskPriorityId, setTaskPriorityId] = useState<number | "">("");
  const [taskSubtaskInput, setTaskSubtaskInput] = useState("");
  const [taskSubtasks, setTaskSubtasks] = useState<string[]>([]);
  const [projectName, setProjectName] = useState("");
  const [projectDescription, setProjectDescription] = useState("");
  const [projectTypeId, setProjectTypeId] = useState<number | "">("");
  const [projectColorId, setProjectColorId] = useState<number | "">("");
  const [projectPriorityId, setProjectPriorityId] = useState<number | "">("");
  const [customColorHex, setCustomColorHex] = useState("#F97316");
  const [isAddingCustomColor, setIsAddingCustomColor] = useState(false);
  const [taskSearch, setTaskSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"ALL" | TaskItem["status"]>("ALL");
  const [focusMode, setFocusMode] = useState(false);
  const [isTaskFilterOpen, setIsTaskFilterOpen] = useState(false);

  function getProjectTypeGlyph(iconUrl: string | null | undefined, label: string): string {
    const candidate = iconUrl?.trim() ?? "";
    if (!candidate || /^https?:\/\//i.test(candidate)) {
      return label.slice(0, 1).toUpperCase();
    }

    return candidate;
  }
  const focusStatuses: TaskItem["status"][] = ["PENDING", "ACTIVE", "IN_PROGRESS", "IN_REVIEW"];

  useEffect(() => {
    void loadDashboard();
  }, [loadDashboard]);

  useEffect(() => {
    if (masters) {
      return;
    }

    void loadMasters();
  }, [loadMasters, masters]);

  const visibleTasks = useMemo(() => {
    if (!selectedProjectId) {
      return tasks;
    }

    const project = projects.find((item) => item.id === selectedProjectId);
    if (!project) {
      return tasks;
    }

    return tasks.filter((task) => task.projectName === project.name);
  }, [projects, selectedProjectId, tasks]);

  const doneCount = visibleTasks.filter((task) => task.status === "COMPLETED").length;
  const completionRate = visibleTasks.length === 0 ? 0 : Math.round((doneCount / visibleTasks.length) * 100);
  const isInitialLoading = isLoading && projects.length === 0 && tasks.length === 0;
  const isMastersPanel = activePanel === "masters";
  const selectedTaskPriority = masters?.priorities.find((priority) => priority.id === taskPriorityId);
  const selectedProjectPriority = masters?.priorities.find((priority) => priority.id === projectPriorityId);
  const selectedProject = selectedProjectId ? projects.find((item) => item.id === selectedProjectId) : null;
  const todayLabel = new Intl.DateTimeFormat("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  }).format(new Date());

  const filteredTasks = useMemo(() => {
    return visibleTasks.filter((task) => {
      if (focusMode && !focusStatuses.includes(task.status)) {
        return false;
      }

      if (statusFilter !== "ALL" && task.status !== statusFilter) {
        return false;
      }

      if (!taskSearch.trim()) {
        return true;
      }

      const normalized = taskSearch.trim().toLowerCase();
      return task.name.toLowerCase().includes(normalized) || task.projectName.toLowerCase().includes(normalized);
    });
  }, [focusMode, focusStatuses, statusFilter, taskSearch, visibleTasks]);

  const projectNameBase = useMemo(() => {
    return projectName
      .trim()
      .toLowerCase()
      .replace(/\s+/g, "_")
      .replace(/[^a-z0-9_]/g, "")
      .replace(/_+/g, "_")
      .replace(/^_+|_+$/g, "");
  }, [projectName]);

  const statusCycle: Array<"ALL" | TaskItem["status"]> = [
    "ALL",
    "ACTIVE",
    "IN_PROGRESS",
    "IN_REVIEW",
    "PENDING",
    "HOLD",
    "COMPLETED",
  ];

  function cycleStatusFilter() {
    setStatusFilter((current) => {
      const currentIndex = statusCycle.indexOf(current);
      const nextIndex = (currentIndex + 1) % statusCycle.length;
      return statusCycle[nextIndex];
    });
  }

  function handleQuickOpenComposer() {
    openComposer();
    setActivePanel("tasks");
  }

  function handleQuickOpenProjectComposer() {
    openProjectComposer();
    setActivePanel("projects");
    setSelectedProjectId(null);
  }

  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      const target = event.target as HTMLElement | null;
      if (
        target &&
        (target.tagName === "INPUT" ||
          target.tagName === "TEXTAREA" ||
          target.tagName === "SELECT" ||
          target.isContentEditable)
      ) {
        return;
      }

      if (event.metaKey || event.ctrlKey || event.altKey) {
        return;
      }

      if (event.key.toLowerCase() === "n") {
        event.preventDefault();
        handleQuickOpenComposer();
      }

      if (event.key.toLowerCase() === "f") {
        event.preventDefault();
        setFocusMode((current) => !current);
      }

      if (event.key.toLowerCase() === "s") {
        event.preventDefault();
        cycleStatusFilter();
      }
    }

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [openComposer, setActivePanel]);

  function handleSidebarSelect(section: SidebarSection) {
    setActivePanel(section);

    if (section === "projects") {
      router.push("/projects");
      return;
    }

    if (section === "dashboard") {
      setSelectedProjectId(null);
      return;
    }

    if (section === "masters") {
      void loadMasters();
    }
  }

  async function handleTaskSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!taskProjectId || !taskPriorityId) {
      return;
    }

    await submitTask({
      projectId: Number(taskProjectId),
      name: taskName,
      description: taskDescription,
      priorityId: Number(taskPriorityId),
    });

    setTaskName("");
    setTaskDescription("");
    setTaskProjectId("");
    setTaskPriorityId("");
    setTaskSubtaskInput("");
    setTaskSubtasks([]);
  }

  function handleAddDraftSubtask() {
    const trimmedName = taskSubtaskInput.trim();
    if (!trimmedName) {
      return;
    }

    setTaskSubtasks((current) => [...current, trimmedName]);
    setTaskSubtaskInput("");
  }

  function handleRemoveDraftSubtask(indexToRemove: number) {
    setTaskSubtasks((current) => current.filter((_, index) => index !== indexToRemove));
  }

  async function handleProjectSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!projectTypeId || !projectColorId || !projectPriorityId) {
      return;
    }

    await submitProject({
      name: projectName,
      description: projectDescription,
      typeId: Number(projectTypeId),
      colorId: Number(projectColorId),
      priorityId: Number(projectPriorityId),
      status: "ACTIVE",
    });

    setProjectName("");
    setProjectDescription("");
    setProjectTypeId("");
    setProjectColorId("");
    setProjectPriorityId("");
  }

  function normalizeHexColor(value: string): string | null {
    const normalized = value.trim().toUpperCase();
    return /^#[0-9A-F]{6}$/.test(normalized) ? normalized : null;
  }

  async function handleAddCustomColor() {
    const normalizedHex = normalizeHexColor(customColorHex);

    if (!normalizedHex || !projectNameBase) {
      return;
    }

    const existingColors = useDashboardStore.getState().masters?.colors ?? [];
    const existingColor = existingColors.find((color) => color.hexCode.toUpperCase() === normalizedHex);
    if (existingColor) {
      setProjectColorId(existingColor.id);
      return;
    }

    const existingCount = existingColors.filter((color) => color.label.toLowerCase().startsWith(`${projectNameBase}_`)).length;
    const generatedName = `${projectNameBase}_${existingCount + 1}`;

    setIsAddingCustomColor(true);

    try {
      await createProjectColorMaster({ name: generatedName, hexCode: normalizedHex });
      setActivePanel("projects");

      const updatedColors = useDashboardStore.getState().masters?.colors ?? [];
      const createdColor = [...updatedColors]
        .reverse()
        .find((color) => color.hexCode.toUpperCase() === normalizedHex);

      if (createdColor) {
        setProjectColorId(createdColor.id);
      }
    } finally {
      setIsAddingCustomColor(false);
    }
  }

  async function handleTaskStatusChange(taskId: number, status: TaskStatus) {
    await setTaskStatus(taskId, status);
  }

  async function handleCreateSubTask(taskId: number, name: string) {
    await createSubTask({ taskId, name });
    await loadDashboard();
  }

  async function handleUpdateSubTask(subTaskId: number, values: { name?: string; status?: TaskStatus }) {
    await updateSubTask(subTaskId, values);
    await loadDashboard();
  }

  async function handleDeleteSubTask(subTaskId: number) {
    await deleteSubTask(subTaskId);
    await loadDashboard();
  }

  async function handleUpdateTaskDetails(
    taskId: number,
    values: { name?: string; description?: string | null; status?: TaskStatus },
  ) {
    await updateTask(taskId, values);
    await loadDashboard();
  }

  function handleSidebarOpenProjects() {
    router.push("/projects");
  }

  function handleSidebarOpenProject(projectId: number) {
    router.push(`/projects/${projectId}`);
  }

  const sidebarSection: SidebarSection = activePanel === "masters" ? "masters" : activePanel === "projects" ? "projects" : "dashboard";

  return (
    <div className="grain-layer min-h-screen px-3 py-4 text-[var(--ink)] sm:px-4 lg:px-6">
      <div className="relative mx-auto flex w-full max-w-none flex-col gap-4 lg:flex-row lg:items-start">
        <div className="w-full lg:w-[220px] lg:flex-none">
          <Sidebar
            activeSection={sidebarSection}
            onSelect={handleSidebarSelect}
            projects={projects}
            selectedProjectId={selectedProjectId}
            onOpenProjects={handleSidebarOpenProjects}
            onOpenProject={handleSidebarOpenProject}
          />
        </div>

        <main className="min-w-0 flex-1 space-y-4">
          <header className="enter-rise rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4">
            <div className="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
              <div className="min-w-0 max-w-2xl">
                <div className="mb-2 inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1 text-[11px] uppercase tracking-[0.14em] text-[var(--muted)]">
                  <CalendarDays className="h-3.5 w-3.5" />
                  {todayLabel}
                </div>
                <h1 className="text-[1.6rem] font-extrabold sm:text-[2.2rem]">MyManager</h1>
                <p className="mt-1 max-w-xl text-sm leading-6 text-[var(--muted)]">
                  A focused workspace for projects and tasks.
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-2 xl:justify-end">
                <div className="rounded-full border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-1.5 text-xs text-[var(--muted)]">
                  {projects.length} projects • {visibleTasks.length} tasks • {completionRate}% done
                </div>
                <Button
                  variant="secondary"
                  onClick={() => {
                    handleQuickOpenProjectComposer();
                  }}
                >
                  <Plus className="mr-1.5 h-4 w-4" /> New Project
                </Button>
                <Button
                  onClick={() => {
                    handleQuickOpenComposer();
                  }}
                >
                  <Plus className="mr-1.5 h-4 w-4" /> New Task
                </Button>
              </div>
            </div>
          </header>

          <div className="grid gap-4">
            <div className="min-w-0 space-y-3">
            {error ? (
              <div className="rounded-md border border-[color:var(--danger)]/60 bg-[#3d1f1b] px-3 py-2.5 text-sm text-[#ffb0a2]">
                {error}
              </div>
            ) : null}

            {isComposerOpen ? (
              <form className="enter-rise rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4" onSubmit={handleTaskSubmit}>
                <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h2 className="text-lg font-extrabold">Create Task</h2>
                    <p className="text-xs text-[var(--muted)]">Fast compose. Stored instantly to backend API.</p>
                  </div>
                  <Button type="button" variant="secondary" onClick={closeComposer}>
                    Close
                  </Button>
                </div>

                <div className="grid gap-2 md:grid-cols-2">
                  <label className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Name</span>
                    <input
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={taskName}
                      onChange={(event) => setTaskName(event.target.value)}
                      placeholder="Wire task creation"
                    />
                  </label>

                  <label className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Project</span>
                    <select
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={taskProjectId}
                      onChange={(event) => setTaskProjectId(event.target.value ? Number(event.target.value) : "")}
                    >
                      <option value="">Choose project</option>
                      {projects.map((project) => (
                        <option key={project.id} value={project.id}>
                          {project.name}
                        </option>
                      ))}
                    </select>
                  </label>

                  <label className="grid gap-1 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Description</span>
                    <textarea
                      className="min-h-20 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-2 outline-none focus:border-[var(--brand-orange)]"
                      value={taskDescription}
                      onChange={(event) => setTaskDescription(event.target.value)}
                      placeholder="Optional description"
                    />
                  </label>

                  <div className="grid gap-1 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Subtasks</span>
                    <div className="flex flex-wrap items-center gap-2">
                      <input
                        className="h-9 min-w-[220px] flex-1 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                        value={taskSubtaskInput}
                        onChange={(event) => setTaskSubtaskInput(event.target.value)}
                        placeholder="Subtask name"
                        onKeyDown={(event) => {
                          if (event.key === "Enter") {
                            event.preventDefault();
                            handleAddDraftSubtask();
                          }
                        }}
                      />
                      <Button
                        type="button"
                        variant="secondary"
                        className="h-9"
                        onClick={handleAddDraftSubtask}
                        disabled={!taskSubtaskInput.trim()}
                      >
                        <Plus className="mr-1.5 h-4 w-4" /> Add Subtask
                      </Button>
                    </div>
                    {taskSubtasks.length ? (
                      <div className="mt-1 flex flex-wrap gap-2">
                        {taskSubtasks.map((subtaskName, index) => (
                          <span
                            key={`${subtaskName}-${index}`}
                            className="inline-flex items-center gap-1 rounded-full border border-[var(--border)] bg-[var(--surface)] px-2.5 py-1 text-xs text-[var(--ink)]"
                          >
                            {subtaskName}
                            <button
                              type="button"
                              className="rounded-full px-1 text-[var(--muted)] hover:bg-[var(--surface-muted)] hover:text-[var(--ink)]"
                              onClick={() => handleRemoveDraftSubtask(index)}
                              aria-label={`Remove ${subtaskName}`}
                            >
                              x
                            </button>
                          </span>
                        ))}
                      </div>
                    ) : null}
                  </div>

                  <div className="grid gap-1 text-sm">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Priority</span>
                    <div className="flex flex-wrap gap-2">
                      {masters?.priorities.map((priority) => {
                        const isSelected = priority.id === taskPriorityId;

                        return (
                          <button
                            key={priority.id}
                            type="button"
                            onClick={() => setTaskPriorityId(priority.id)}
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
                </div>

                <div className="mt-3 flex justify-end gap-2">
                  <Button type="button" variant="secondary" onClick={closeComposer}>
                    Cancel
                  </Button>
                  <Button type="submit" disabled={isLoading}>
                    <Plus className="mr-1.5 h-4 w-4" /> Add Task
                  </Button>
                </div>
              </form>
            ) : null}

            {isProjectComposerOpen ? (
              <form className="enter-rise rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4" onSubmit={handleProjectSubmit}>
                <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h2 className="text-lg font-extrabold">Create Project</h2>
                    <p className="text-xs text-[var(--muted)]">Add a project with its type, color, and priority.</p>
                  </div>
                  <Button type="button" variant="secondary" onClick={closeProjectComposer}>
                    Close
                  </Button>
                </div>

                <div className="grid gap-2 md:grid-cols-2">
                  <label className="grid gap-1 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Name</span>
                    <input
                      className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 outline-none focus:border-[var(--brand-orange)]"
                      value={projectName}
                      onChange={(event) => setProjectName(event.target.value)}
                      placeholder="Website relaunch"
                    />
                  </label>

                  <div className="grid gap-2 text-sm md:col-span-2 md:grid-cols-[minmax(0,1fr)_auto] md:items-start">
                    <div className="grid gap-1">
                      <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Type</span>
                      <div className="flex items-start gap-2 overflow-x-auto pb-1">
                        {masters?.projectTypes.map((type) => {
                          const isSelected = type.id === projectTypeId;

                          return (
                            <button
                              key={type.id}
                              type="button"
                              className={`flex h-[78px] w-[78px] shrink-0 flex-col items-center justify-center gap-1 rounded-md border p-1.5 text-center transition ${
                                isSelected
                                  ? "border-[var(--brand-orange)] bg-[var(--surface)]"
                                  : "border-[var(--border)] bg-[var(--surface-muted)] hover:border-[var(--border-strong)]"
                              }`}
                              onClick={() => setProjectTypeId(type.id)}
                            >
                              <div className="grid h-8 w-8 place-items-center rounded-full border border-[var(--border)] bg-[var(--paper)] text-lg leading-none">
                                {getProjectTypeGlyph(type.iconUrl, type.label)}
                              </div>
                              <span className="w-full truncate px-1 text-[10px] font-semibold text-[var(--ink)]">{type.label}</span>
                            </button>
                          );
                        })}
                      </div>
                    </div>

                    <div className="grid gap-1 md:justify-items-end">
                      <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Priority</span>
                      <div className="flex flex-wrap justify-end gap-2">
                        {masters?.priorities.map((priority) => {
                          const isSelected = priority.id === projectPriorityId;

                          return (
                            <button
                              key={priority.id}
                              type="button"
                              onClick={() => setProjectPriorityId(priority.id)}
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
                      <p className="text-right text-xs text-[var(--muted)]">
                        {selectedProjectPriority
                          ? `Selected: ${selectedProjectPriority.code} - ${selectedProjectPriority.title}`
                          : "Select one priority flag"}
                      </p>
                    </div>
                  </div>

                  <div className="grid gap-2 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Color</span>

                    <div className="flex flex-wrap items-center gap-2">
                      {masters?.colors.map((color) => {
                        const isSelected = color.id === projectColorId;

                        return (
                          <button
                            key={color.id}
                            type="button"
                            className={`inline-flex h-7 w-7 items-center justify-center rounded-full border transition ${
                              isSelected
                                ? "border-[var(--brand-orange)] bg-[var(--surface)]"
                                : "border-[var(--border)] bg-[var(--surface-muted)] hover:border-[var(--border-strong)]"
                            }`}
                            onClick={() => setProjectColorId(color.id)}
                            aria-label={`Select color ${color.hexCode.toUpperCase()}`}
                            title={color.hexCode.toUpperCase()}
                          >
                            <span
                              className="inline-block h-4 w-4 rounded-full border border-[var(--border)]"
                              style={{ backgroundColor: color.hexCode }}
                              aria-hidden="true"
                            />
                          </button>
                        );
                      })}

                      <input
                        type="color"
                        className="h-7 w-7 cursor-pointer rounded-full border border-dashed border-[var(--border-strong)] bg-[var(--surface-muted)] p-0"
                        value={customColorHex}
                        onChange={(event) => setCustomColorHex(event.target.value)}
                        aria-label="Pick custom color"
                        title="Pick custom color"
                      />

                      <Button
                        type="button"
                        variant="secondary"
                        size="md"
                        className="h-7 px-2 text-xs"
                        onClick={() => {
                          void handleAddCustomColor();
                        }}
                        disabled={isLoading || isAddingCustomColor || !projectNameBase}
                        title={projectNameBase ? "Add custom color" : "Enter project name first"}
                      >
                        +
                      </Button>
                    </div>

                  </div>

                  <label className="grid gap-1 text-sm md:col-span-2">
                    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Description</span>
                    <textarea
                      className="min-h-20 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-2 outline-none focus:border-[var(--brand-orange)]"
                      value={projectDescription}
                      onChange={(event) => setProjectDescription(event.target.value)}
                      placeholder="Optional description"
                    />
                  </label>
                </div>

                <div className="mt-3 flex justify-end gap-2">
                  <Button type="button" variant="secondary" onClick={closeProjectComposer}>
                    Cancel
                  </Button>
                  <Button type="submit" disabled={isLoading || !masters || !projectName.trim()}>
                    Save Project
                  </Button>
                </div>
              </form>
            ) : null}

            {isInitialLoading ? (
              <div className="tactile-panel rounded-lg p-4 text-sm text-[var(--muted)]">
                <p className="font-semibold text-[var(--ink)]">Syncing dashboard signal</p>
                <p>Fetching projects and tasks from the backend API.</p>
              </div>
            ) : (
              <section className="space-y-3">

                {!projects.length ? (
                  <div className="rounded-md border border-dashed border-[var(--border-strong)] bg-[var(--surface-muted)] p-3 text-sm text-[var(--muted)]">
                    <p>No projects yet. Create one from the header action.</p>
                    <Button
                      className="mt-3"
                      size="lg"
                      onClick={() => {
                        handleQuickOpenProjectComposer();
                      }}
                    >
                      <Plus className="mr-1.5 h-4 w-4" /> Create your first project
                    </Button>
                  </div>
                ) : null}

                {activePanel === "masters" && masters ? (
                  <MastersTabs
                    masters={masters}
                    isLoading={isLoading}
                    onCreateProjectType={async (name, emoji) => {
                      await createProjectTypeMaster({ name, iconUrl: emoji ?? null });
                    }}
                    onUpdateProjectType={async (id, name, emoji) => {
                      await updateProjectTypeMaster({ id, name, iconUrl: emoji ?? null });
                    }}
                    onCreatePriority={async (code, title) => {
                      await createPriorityMaster({ code, title });
                    }}
                    onUpdatePriority={async (id, code, title) => {
                      await updatePriorityMaster({ id, code, title });
                    }}
                    onCreateColor={async (name, hexCode) => {
                      await createProjectColorMaster({ name, hexCode });
                    }}
                    onUpdateColor={async (id, name, hexCode) => {
                      await updateProjectColorMaster({ id, name, hexCode });
                    }}
                    onDeleteColor={async (id) => {
                      await deleteProjectColorMaster(id);
                    }}
                  />
                ) : null}
              </section>
            )}
            </div>

            {!isMastersPanel ? (
              <div className="min-w-0 space-y-3">
                {isTaskFilterOpen ? (
                  <div className="rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-3">
                    <div className="flex items-center gap-2 overflow-x-auto whitespace-nowrap">
                      <label className="relative block">
                        <Search className="pointer-events-none absolute left-2.5 top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--muted)]" />
                        <input
                          value={taskSearch}
                          onChange={(event) => setTaskSearch(event.target.value)}
                          placeholder="Filter tasks by name or project"
                          className="h-10 w-[min(52vw,640px)] min-w-[220px] rounded-md border border-[var(--border)] bg-[var(--surface-muted)] pl-8 pr-3 outline-none focus:border-[var(--brand-orange)]"
                        />
                      </label>

                      <select
                        value={statusFilter}
                        onChange={(event) => setStatusFilter(event.target.value as "ALL" | TaskItem["status"])}
                        className="h-10 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 outline-none focus:border-[var(--brand-orange)]"
                      >
                        <option value="ALL">All statuses</option>
                        <option value="ACTIVE">Active</option>
                        <option value="IN_PROGRESS">In Progress</option>
                        <option value="IN_REVIEW">In Review</option>
                        <option value="PENDING">Pending</option>
                        <option value="HOLD">Hold</option>
                        <option value="COMPLETED">Completed</option>
                      </select>

                    </div>

                    <p className="mt-2 text-xs text-[var(--muted)]">
                      Showing {filteredTasks.length} of {visibleTasks.length} tasks
                      {selectedProject ? ` in ${selectedProject.name}.` : "."}
                      {focusMode ? " Focus mode is on." : ""}
                    </p>
                  </div>
                ) : null}

                <TaskList
                  tasks={filteredTasks}
                  title={selectedProject ? `${selectedProject.name} Queue` : "Task Queue"}
                  disabled={isLoading}
                  onStatusChange={handleTaskStatusChange}
                  onUpdateTask={handleUpdateTaskDetails}
                  onCreateSubTask={handleCreateSubTask}
                  onUpdateSubTask={handleUpdateSubTask}
                  onDeleteSubTask={handleDeleteSubTask}
                  headerAction={
                    <>
                      <Button
                        type="button"
                        variant={focusMode ? "primary" : "secondary"}
                        size="md"
                        className="h-8 px-2"
                        aria-label={focusMode ? "Disable focus mode" : "Enable focus mode"}
                        title={focusMode ? "Focus mode on" : "Focus mode off"}
                        onClick={() => setFocusMode((current) => !current)}
                      >
                        <Crosshair className={focusMode ? "h-4 w-4" : "h-4 w-4 opacity-70"} />
                        <span className="ml-1 text-[10px] font-semibold">{focusMode ? "ON" : "OFF"}</span>
                      </Button>
                      <Button
                        type="button"
                        variant={isTaskFilterOpen ? "primary" : "secondary"}
                        size="md"
                        className="h-8 w-8 px-0"
                        aria-label={isTaskFilterOpen ? "Hide filters" : "Show filters"}
                        title={isTaskFilterOpen ? "Hide filters" : "Show filters"}
                        onClick={() => setIsTaskFilterOpen((current) => !current)}
                      >
                        <SlidersHorizontal className="h-4 w-4" />
                      </Button>
                    </>
                  }
                />
              </div>
            ) : null}
          </div>
        </main>
      </div>
    </div>
  );
}
