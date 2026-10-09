import { useEffect, useRef, useState } from "react";
import { TASK_FILTER_IDS, TASK_FILTERS } from "@/features/dashboard/widgets/task_list/constants/task_filters.js";
import { getApiErrorMessage, isVersionConflict } from "@/services/api_client.js";
import * as repository from "./dashboard_repository.js";
import { resolveProjectColor } from "./project_color_utils.js";
import { getTaskStatus, TASK_STATUSES } from "./task_status.js";
import { normalizeRecurrence } from "./task_recurrence.js";

function getDescendantProjectIds(projects, parentProjectId) {
  return projects
    .filter((project) => project.parentProjectId === parentProjectId)
    .flatMap((project) => [project.id, ...getDescendantProjectIds(projects, project.id)]);
}

export function useDashboardController() {
  const [tasks, setTasks] = useState([]);
  const [projects, setProjects] = useState([]);
  const [summary, setSummary] = useState(null);
  const [asOfDate, setAsOfDate] = useState("");
  const [dashboardTimezone, setDashboardTimezone] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [isMutating, setIsMutating] = useState(false);
  const [filteredTasks, setFilteredTasks] = useState(null);
  const [isFiltering, setIsFiltering] = useState(false);
  const [filterError, setFilterError] = useState("");
  const [filterRefreshToken, setFilterRefreshToken] = useState(0);
  const mutationPending = useRef(false);
  const [activeFilter, setActiveFilter] = useState(TASK_FILTER_IDS.OPEN);
  const [searchTerm, setSearchTerm] = useState("");
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [editingTaskId, setEditingTaskId] = useState(null);
  const [taskClosureDialog, setTaskClosureDialog] = useState(null);
  const [taskClosureDialogError, setTaskClosureDialogError] = useState("");
  const [pendingTaskDeletion, setPendingTaskDeletion] = useState(null);
  const [isCreateProjectDialogOpen, setIsCreateProjectDialogOpen] = useState(false);
  const [editingProjectId, setEditingProjectId] = useState(null);
  const [taskDialogProjectId, setTaskDialogProjectId] = useState("");
  const [projectPendingDeletionId, setProjectPendingDeletionId] = useState(null);
  const [selectedProjectId, setSelectedProjectId] = useState(null);
  const [notification, setNotification] = useState(null);

  function notify(message, tone = "success", celebrate = false, color = null) {
    setNotification({ id: crypto.randomUUID(), message, tone, celebrate, color });
  }

  useEffect(() => {
    if (!notification) return undefined;
    const timeoutId = window.setTimeout(() => setNotification((current) => current?.id === notification.id ? null : current), 4000);
    return () => window.clearTimeout(timeoutId);
  }, [notification]);

  async function refreshDashboard() {
    const data = await repository.getDashboard();
    setProjects(data.projects);
    setTasks([...data.recentTasks, ...data.upcomingTasks]);
    setSummary(data.summary);
    setAsOfDate(data.asOfDate);
    setDashboardTimezone(data.timezone);
    setLoadError("");
    return data;
  }

  useEffect(() => {
    let active = true;
    repository.getDashboard()
      .then((data) => {
        if (!active) return;
        setProjects(data.projects);
        setTasks([...data.recentTasks, ...data.upcomingTasks]);
        setSummary(data.summary);
        setAsOfDate(data.asOfDate);
        setDashboardTimezone(data.timezone);
      })
      .catch((error) => { if (active) setLoadError(error.response?.data?.error?.message ?? error.message); })
      .finally(() => { if (active) setIsLoading(false); });
    return () => { active = false; };
  }, []);

  useEffect(() => {
    if (!asOfDate || !dashboardTimezone) return undefined;
    const formatter = new Intl.DateTimeFormat("en", { timeZone: dashboardTimezone, year: "numeric", month: "2-digit", day: "2-digit" });
    const intervalId = window.setInterval(() => {
      const parts = Object.fromEntries(formatter.formatToParts(new Date()).map(({ type, value }) => [type, value]));
      if (`${parts.year}-${parts.month}-${parts.day}` !== asOfDate) void refreshDashboard().catch((error) => setLoadError(getApiErrorMessage(error)));
    }, 60000);
    return () => window.clearInterval(intervalId);
  }, [asOfDate, dashboardTimezone]);

  useEffect(() => {
    if (isLoading || loadError) return undefined;
    let active = true;
    setFilteredTasks(null);
    setIsFiltering(true);
    const timer = window.setTimeout(() => {
      repository.getTaskList({ status: activeFilter, search: searchTerm.trim() || undefined, dateScope: "recent" })
        .then((items) => { if (active) { setFilteredTasks(items); setFilterError(""); } })
        .catch((error) => { if (active) setFilterError(getApiErrorMessage(error)); })
        .finally(() => { if (active) setIsFiltering(false); });
    }, searchTerm ? 250 : 0);
    return () => { active = false; window.clearTimeout(timer); };
  }, [activeFilter, searchTerm, summary, isLoading, loadError, filterRefreshToken]);

  const projectName = (projectId) => projects.find((project) => project.id === projectId)?.name ?? "General";
  const projectColor = (projectId) => resolveProjectColor(projectId, projects) ?? "var(--project-neutral)";
  const today = asOfDate;
  const upcomingTasks = tasks
    .filter((task) => getTaskStatus(task) === TASK_STATUSES.OPEN && task.dueDate && task.dueDate > today)
    .sort((first, second) => first.dueDate.localeCompare(second.dueDate) || first.title.localeCompare(second.title));
  const normalizedSearch = searchTerm.trim().toLowerCase();
  const selectedProjectIds = selectedProjectId
    ? [selectedProjectId, ...getDescendantProjectIds(projects, selectedProjectId)]
    : null;
  const matchesTaskScope = (task) => {
    const matchesDate = !task.dueDate || task.dueDate <= today;
    const matchesProject = !selectedProjectIds || selectedProjectIds.includes(task.projectId);
    const matchesSearch = !normalizedSearch || task.title.toLowerCase().includes(normalizedSearch);
    return matchesDate && matchesProject && matchesSearch;
  };
  const filterCounts = Object.fromEntries(TASK_FILTERS.map(({ id }) => [id, 0]));
  for (const task of tasks.filter(matchesTaskScope)) {
    filterCounts[TASK_FILTER_IDS.ALL] += 1;
    filterCounts[getTaskStatus(task).toLowerCase()] += 1;
  }
  const visibleTasks = (filteredTasks ?? tasks).filter((task) => {
    const matchesFilter = activeFilter === TASK_FILTER_IDS.ALL
      || (activeFilter === TASK_FILTER_IDS.OPEN && getTaskStatus(task) === TASK_STATUSES.OPEN)
      || (activeFilter === TASK_FILTER_IDS.COMPLETED && getTaskStatus(task) === TASK_STATUSES.COMPLETED)
      || (activeFilter === TASK_FILTER_IDS.SKIPPED && getTaskStatus(task) === TASK_STATUSES.SKIPPED)
      || (activeFilter === TASK_FILTER_IDS.MISSED && getTaskStatus(task) === TASK_STATUSES.MISSED);
    return matchesTaskScope(task) && matchesFilter;
  });

  const projectStats = projects;
  const selectedProject = projectStats.find((project) => project.id === selectedProjectId) ?? null;
  const completedCount = summary?.completedCount ?? 0;
  const overdueCount = summary?.overdueCount ?? 0;
  const dueTodayCount = summary?.dueTodayCount ?? 0;
  const pendingTodayCount = summary?.pendingTodayCount ?? 0;
  const completedTodayCount = summary?.completedTodayCount ?? 0;

  async function runMutation(action, message, { celebrate = false, color = null, refreshTaskId = null, onError = null } = {}) {
    if (mutationPending.current) return false;
    mutationPending.current = true;
    setIsMutating(true);
    try {
      let result;
      try {
        result = await action();
      } catch (error) {
        const errorCode = error.response?.data?.error?.code;
        const shouldRefresh = isVersionConflict(error) || ["TASK_NOT_OVERDUE", "TASK_NOT_RECURRING", "TASK_NOT_OPEN", "TASK_NOT_REOPENABLE"].includes(errorCode);
        if (shouldRefresh) {
          try {
            await refreshDashboard();
          } catch {
            setLoadError("Could not refresh the dashboard. Retry to load the latest data.");
          }
        }
        const conflictMessage = isVersionConflict(error)
          ? "This task changed elsewhere. The latest version is loaded."
          : errorCode === "TASK_NOT_OVERDUE"
            ? "This task is no longer overdue. The latest data is loaded."
            : errorCode === "TASK_NOT_RECURRING"
              ? "Only recurring tasks can be skipped."
              : errorCode === "TASK_NOT_OPEN"
                ? "This task is no longer open. The latest data is loaded."
                : errorCode === "TASK_NOT_REOPENABLE"
                  ? "Skipped and missed tasks cannot be reopened."
                : getApiErrorMessage(error);
        if (!onError?.(error)) notify(conflictMessage, "error");
        return false;
      }
      if (refreshTaskId && result?.id) {
        setTasks((currentTasks) => currentTasks.map((task) => task.id === refreshTaskId ? result : task));
      }
      try {
        await refreshDashboard();
        notify(message, "success", celebrate, color);
      } catch {
        setLoadError("Saved, but the dashboard could not refresh. Retry to load the latest data.");
      }
      return result ?? true;
    } finally {
      mutationPending.current = false;
      setIsMutating(false);
    }
  }

  function toggleTask(taskId) {
    const task = tasks.find((candidate) => candidate.id === taskId);
    if (!task) {
      notify("Task not found.", "error");
      return false;
    }
    const status = getTaskStatus(task);
    if (status === TASK_STATUSES.SKIPPED || status === TASK_STATUSES.MISSED) {
      notify("Skipped and missed tasks cannot be reopened.", "error");
      return false;
    }
    if (status !== TASK_STATUSES.OPEN && status !== TASK_STATUSES.COMPLETED) {
      notify("This task has an unsupported status.", "error");
      return false;
    }
    const reopening = status === TASK_STATUSES.COMPLETED;
    return runMutation(
      () => reopening ? repository.reopenTask(taskId, task.version) : repository.completeTask(taskId, task.version),
      reopening ? "Task reopened." : "Task completed!",
      { celebrate: !reopening, color: projectColor(task.projectId) },
    );
  }

  function closeOverdueTask(taskId, command, reason = "") {
    const task = tasks.find((candidate) => candidate.id === taskId);
    if (!task) {
      notify("Task not found.", "error");
      return false;
    }
    if (getTaskStatus(task) !== TASK_STATUSES.OPEN || !task.dueDate || !asOfDate || task.dueDate >= asOfDate) {
      notify("This task is no longer overdue. The latest data is loaded.", "error");
      void refreshDashboard().catch(() => setLoadError("Could not refresh the dashboard. Retry to load the latest data."));
      return false;
    }
    if (command === "skip" && (!task.recurrence?.frequency || task.recurrence.frequency === "one_time")) {
      notify("Only recurring tasks can be skipped.", "error");
      return false;
    }
    const normalizedReason = reason.trim();
    if (!normalizedReason || normalizedReason.length > 200) {
      notify(`Enter a ${command} reason between 1 and 200 characters.`, "error");
      return false;
    }
    const skip = command === "skip";
    return runMutation(
      () => skip ? repository.skipTask(taskId, task.version, normalizedReason) : repository.missTask(taskId, task.version, normalizedReason),
      skip ? "Task skipped." : "Task marked as missed.",
      {
        refreshTaskId: taskId,
        onError: (error) => {
          if (error.response?.status !== 400 || error.response?.data?.error?.code !== "VALIDATION_ERROR") return false;
          setTaskClosureDialogError("Enter a reason between 1 and 200 characters.");
          return true;
        },
      },
    );
  }

  async function confirmTaskClosure(reason) {
    if (!taskClosureDialog) return false;
    const result = await closeOverdueTask(taskClosureDialog.taskId, taskClosureDialog.action, reason);
    if (result) setTaskClosureDialog(null);
    return result;
  }

  function showTaskClosureDialog(taskId, action) {
    setTaskClosureDialogError("");
    setTaskClosureDialog({ taskId, action });
  }

  function clearTaskClosureDialogError() {
    setTaskClosureDialogError("");
  }

  function addSubtask(taskId, title) {
    const normalizedTitle = title.trim();
    const task = tasks.find((candidate) => candidate.id === taskId);
    if (!normalizedTitle || !task) {
      notify(!task ? "Task not found." : "Enter a subtask name.", "error");
      return false;
    }
    if ([TASK_STATUSES.SKIPPED, TASK_STATUSES.MISSED].includes(getTaskStatus(task))) {
      notify("Reopen this task before adding subtasks.", "error");
      return false;
    }
    return runMutation(() => repository.createSubtask(taskId, normalizedTitle), task.completed ? "Subtask added. Task reopened." : "Subtask added.");
  }

  function toggleSubtask(taskId, subtaskId) {
    const task = tasks.find((candidate) => candidate.id === taskId);
    const subtask = task?.subtasks.find((candidate) => candidate.id === subtaskId);
    if (!subtask || !task) {
      notify("Subtask not found.", "error");
      return false;
    }
    if ([TASK_STATUSES.SKIPPED, TASK_STATUSES.MISSED].includes(getTaskStatus(task))) {
      notify("Reopen this task before changing subtask completion.", "error");
      return false;
    }
    return runMutation(
      () => subtask.completed ? repository.reopenSubtask(taskId, subtaskId, subtask.version) : repository.completeSubtask(taskId, subtaskId, subtask.version),
      subtask.completed ? "Subtask reopened." : "Subtask completed.",
    );
  }

  function editSubtask(taskId, subtaskId, title) {
    const normalizedTitle = title.trim();
    const parentTask = tasks.find((task) => task.id === taskId);
    const subtask = parentTask?.subtasks.find((candidate) => candidate.id === subtaskId);
    if (!normalizedTitle || !subtask) {
      notify(!subtask ? "Subtask not found." : "Enter a subtask name.", "error");
      return false;
    }
    return runMutation(() => repository.updateSubtask(taskId, subtaskId, normalizedTitle, subtask.version), "Subtask updated.");
  }

  async function createTask({ title, projectId, dueDate, recurrence }) {
    const normalizedTitle = title.trim();
    if (!normalizedTitle) {
      notify("Enter a task name.", "error");
      return false;
    }

    if (recurrence?.frequency === "custom" && (!Number.isInteger(Number(recurrence.interval)) || Number(recurrence.interval) < 1 || Number(recurrence.interval) > 365)) {
      notify("Choose a custom interval between 1 and 365.", "error");
      return false;
    }

    const schedule = normalizeRecurrence(recurrence);
    const body = { title: normalizedTitle, projectId: projectId ? Number(projectId) : null, dueDate: dueDate || null, recurrence: schedule };

    if (editingTaskId) {
      const editingTask = tasks.find((task) => task.id === editingTaskId);
      if (!editingTask) {
        notify("Task not found.", "error");
        return false;
      }
      if (!await runMutation(() => repository.updateTask(editingTaskId, { ...body, version: editingTask.version }), "Task updated.")) return false;
      setEditingTaskId(null);
      setIsCreateDialogOpen(false);
      return true;
    }

    const createdTask = await runMutation(() => repository.createTask(body), "Task created.");
    if (!createdTask) return false;
    setTasks((currentTasks) => currentTasks.some((task) => task.id === createdTask.id) ? currentTasks : [createdTask, ...currentTasks]);
    setEditingTaskId(createdTask.id);
    setTaskDialogProjectId(createdTask.projectId ?? "");
    setActiveFilter(TASK_FILTER_IDS.OPEN);
    return true;
  }

  function requestDeleteTask(taskId, subtaskId = null) {
    const task = tasks.find((candidate) => candidate.id === taskId);
    if (!task || (subtaskId && !task.subtasks.some((subtask) => subtask.id === subtaskId))) {
      notify(subtaskId ? "Subtask not found." : "Task not found.", "error");
      return;
    }
    setPendingTaskDeletion({ taskId, subtaskId });
  }

  async function confirmDeleteTask() {
    if (!pendingTaskDeletion) return;
    const { taskId, subtaskId } = pendingTaskDeletion;
    const task = tasks.find((candidate) => candidate.id === taskId);
    if (!task || (subtaskId && !task.subtasks.some((subtask) => subtask.id === subtaskId))) {
      notify(subtaskId ? "Subtask not found." : "Task not found.", "error");
      setPendingTaskDeletion(null);
      return;
    }
    const removed = await runMutation(
      () => subtaskId ? repository.deleteSubtask(taskId, subtaskId) : repository.deleteTask(taskId),
      subtaskId ? "Subtask deleted." : "Task deleted.",
    );
    if (!removed) return;
    setPendingTaskDeletion(null);
  }

  async function createProject({ name, parentProjectId, color }) {
    const normalizedName = name.trim();
    if (!normalizedName) {
      notify("Enter a project name.", "error");
      return false;
    }

    const selectedColor = typeof color === "string" && /^#[0-9a-f]{6}$/i.test(color)
      ? color.toUpperCase()
      : projects.find((project) => project.id === editingProjectId)?.color;
    if (!selectedColor) {
      notify("Choose a project color.", "error");
      return false;
    }
    if (projects.some((project) => project.id !== editingProjectId && project.color?.toUpperCase() === selectedColor)) {
      notify("Choose an unused project color.", "error");
      return false;
    }

    const parentId = parentProjectId ? Number(parentProjectId) : null;
    const editingDescendants = editingProjectId ? getDescendantProjectIds(projects, editingProjectId) : [];
    if (parentId && (!projects.some((project) => project.id === parentId) || parentId === editingProjectId || editingDescendants.includes(parentId))) {
      notify("Choose a valid parent project.", "error");
      return false;
    }

    if (editingProjectId) {
      const editingProject = projects.find((project) => project.id === editingProjectId);
      if (!editingProject) {
        notify("Project not found.", "error");
        return false;
      }
      if (!await runMutation(() => repository.updateProject(editingProjectId, { name: normalizedName, parentProjectId: parentId, color: selectedColor, version: editingProject.version }), "Project updated.")) return false;
      setSelectedProjectId(editingProjectId);
      setEditingProjectId(null);
      setIsCreateProjectDialogOpen(false);
      return true;
    }

    const created = await runMutation(() => repository.createProject({ name: normalizedName, parentProjectId: parentId, color: selectedColor }), "Project created.");
    if (!created) return false;
    setSelectedProjectId(created.id);
    setIsCreateProjectDialogOpen(false);
    return true;
  }

  async function deleteProject(projectId) {
    const project = projects.find((candidate) => candidate.id === projectId);
    if (!project) {
      notify("Project not found.", "error");
      return false;
    }
    const removed = await runMutation(() => repository.deleteProject(projectId), "Project deleted.");
    if (!removed) return false;
    setSelectedProjectId((currentProjectId) => currentProjectId === projectId ? removed.reassignedProjectId : currentProjectId);
    return true;
  }

  function requestDeleteProject(projectId) {
    if (projects.some((project) => project.id === projectId)) setProjectPendingDeletionId(projectId);
    else notify("Project not found.", "error");
  }

  async function confirmDeleteProject() {
    if (!projectPendingDeletionId) return;
    if (await deleteProject(projectPendingDeletionId)) setProjectPendingDeletionId(null);
  }

  function selectProject(projectId) {
    setSelectedProjectId((currentProjectId) => currentProjectId === projectId ? null : projectId);
  }

  return {
    activeFilter,
    asOfDate,
    isLoading,
    loadError,
    retryLoad: async () => {
      setIsLoading(true);
      try { await refreshDashboard(); } catch (error) { setLoadError(error.response?.data?.error?.message ?? error.message); }
      finally { setIsLoading(false); }
    },
    isMutating,
    isFiltering,
    filterError,
    retryFilter: () => setFilterRefreshToken((value) => value + 1),
    notification,
    overdueCount,
    dueTodayCount,
    pendingTodayCount,
    completedTodayCount,
    dismissNotification: () => setNotification(null),
    completedCount,
    closeProjectDialog: () => {
      setIsCreateProjectDialogOpen(false);
      setEditingProjectId(null);
    },
    addSubtask,
    editSubtask,
    createTask,
    requestDeleteTask,
    confirmDeleteTask,
    cancelDeleteTask: () => setPendingTaskDeletion(null),
    taskClosureDialog: taskClosureDialog && {
      task: tasks.find((task) => task.id === taskClosureDialog.taskId) ?? null,
      action: taskClosureDialog.action,
    },
    taskClosureDialogError,
    openTaskClosureDialogSkip: (taskId) => showTaskClosureDialog(taskId, "skip"),
    openMissTaskDialog: (taskId) => showTaskClosureDialog(taskId, "miss"),
    cancelTaskClosureDialog: () => {
      setTaskClosureDialog(null);
      setTaskClosureDialogError("");
    },
    clearTaskClosureDialogError,
    confirmTaskClosure,
    taskPendingDeletion: pendingTaskDeletion && (() => {
      const task = tasks.find((candidate) => candidate.id === pendingTaskDeletion.taskId);
      const subtask = task?.subtasks.find((candidate) => candidate.id === pendingTaskDeletion.subtaskId);
      return pendingTaskDeletion.subtaskId ? subtask && { title: subtask.title, kind: "subtask" } : task && { title: task.title, kind: "task", subtaskCount: task.subtasks.length };
    })(),
    editingTask: tasks.find((task) => task.id === editingTaskId) ?? null,
    createProject,
    deleteProject,
    requestDeleteProject,
    confirmDeleteProject,
    cancelDeleteProject: () => setProjectPendingDeletionId(null),
    editingProject: projects.find((project) => project.id === editingProjectId) ?? null,
    projectPendingDeletion: projects.find((project) => project.id === projectPendingDeletionId) ?? null,
    isCreateDialogOpen,
    isCreateProjectDialogOpen,
    openTaskDialog: (projectId = selectedProjectId) => {
      setEditingTaskId(null);
      setTaskDialogProjectId(projectId ?? "");
      setIsCreateDialogOpen(true);
    },
    openEditTaskDialog: async (taskId) => {
      try {
        const task = await repository.getTask(taskId);
        setTasks((currentTasks) => currentTasks.map((candidate) => candidate.id === taskId ? task : candidate));
        setEditingTaskId(taskId);
        setTaskDialogProjectId(task.projectId);
        setIsCreateDialogOpen(true);
      } catch (error) { notify(getApiErrorMessage(error), "error"); }
    },
    openProjectDialog: () => {
      setEditingProjectId(null);
      setIsCreateProjectDialogOpen(true);
    },
    openEditProjectDialog: async (projectId) => {
      try {
        const project = await repository.getProject(projectId);
        setProjects((currentProjects) => currentProjects.map((candidate) => candidate.id === projectId ? project : candidate));
        setEditingProjectId(projectId);
        setIsCreateProjectDialogOpen(true);
      } catch (error) { notify(getApiErrorMessage(error), "error"); }
    },
    closeTaskDialog: () => {
      setIsCreateDialogOpen(false);
      setEditingTaskId(null);
    },
    openTaskCount: tasks.filter((task) => getTaskStatus(task) === TASK_STATUSES.OPEN).length,
    projectName,
    projectColor,
    projectStats,
    projects,
    selectProject,
    selectedProject,
    selectedProjectId,
    taskDialogProjectId,
    selectedProjectName: projectName(selectedProjectId),
    searchTerm,
    setActiveFilter,
    setSearchTerm,
    tasks: visibleTasks,
    filterCounts,
    upcomingTasks,
    toggleTask,
    toggleSubtask,
    totalCount: summary?.totalCount ?? 0,
    openCount: summary?.openCount ?? 0,
    skippedCount: summary?.skippedCount ?? 0,
    missedCount: summary?.missedCount ?? 0,
    completionRate: summary?.completionRate ?? 0,
  };
}
