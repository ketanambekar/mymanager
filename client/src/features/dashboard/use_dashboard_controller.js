import { useEffect, useRef, useState } from "react";
import { TASK_FILTER_IDS } from "@/features/dashboard/widgets/task_list/constants/task_filters.js";
import { getApiErrorMessage, isVersionConflict } from "@/services/api_client.js";
import * as repository from "./dashboard_repository.js";
import { resolveProjectColor } from "./project_color_utils.js";
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
    .filter((task) => !task.completed && task.dueDate && task.dueDate > today)
    .sort((first, second) => first.dueDate.localeCompare(second.dueDate) || first.title.localeCompare(second.title));
  const normalizedSearch = searchTerm.trim().toLowerCase();
  const selectedProjectIds = selectedProjectId
    ? [selectedProjectId, ...getDescendantProjectIds(projects, selectedProjectId)]
    : null;
  const visibleTasks = (filteredTasks ?? tasks).filter((task) => {
    const matchesDate = !task.dueDate || task.dueDate <= today;
    const matchesFilter = activeFilter === TASK_FILTER_IDS.ALL
      || (activeFilter === TASK_FILTER_IDS.OPEN && !task.completed)
      || (activeFilter === TASK_FILTER_IDS.COMPLETED && task.completed);
    const matchesProject = !selectedProjectIds || selectedProjectIds.includes(task.projectId);
    const matchesSearch = !normalizedSearch || task.title.toLowerCase().includes(normalizedSearch);
    return matchesDate && matchesFilter && matchesProject && matchesSearch;
  });

  const projectStats = projects;
  const selectedProject = projectStats.find((project) => project.id === selectedProjectId) ?? null;
  const completedCount = summary?.completedCount ?? 0;
  const overdueCount = summary?.overdueCount ?? 0;
  const dueTodayCount = summary?.dueTodayCount ?? 0;
  const pendingTodayCount = summary?.pendingTodayCount ?? 0;
  const completedTodayCount = summary?.completedTodayCount ?? 0;

  async function runMutation(action, message, { celebrate = false, color = null } = {}) {
    if (mutationPending.current) return false;
    mutationPending.current = true;
    setIsMutating(true);
    try {
      let result;
      try {
        result = await action();
      } catch (error) {
        if (isVersionConflict(error)) await refreshDashboard().catch(() => {});
        notify(isVersionConflict(error) ? "This item changed elsewhere. The latest version is loaded." : getApiErrorMessage(error), "error");
        return false;
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
    return runMutation(
      () => task.completed ? repository.reopenTask(taskId, task.version) : repository.completeTask(taskId, task.version),
      task.completed ? "Task reopened." : "Task completed!",
      { celebrate: !task.completed, color: projectColor(task.projectId) },
    );
  }

  function addSubtask(taskId, title) {
    const normalizedTitle = title.trim();
    const task = tasks.find((candidate) => candidate.id === taskId);
    if (!normalizedTitle || !task) {
      notify(!task ? "Task not found." : "Enter a subtask name.", "error");
      return false;
    }
    return runMutation(() => repository.createSubtask(taskId, normalizedTitle), task.completed ? "Subtask added. Task reopened." : "Subtask added.");
  }

  function toggleSubtask(taskId, subtaskId) {
    const task = tasks.find((candidate) => candidate.id === taskId);
    const subtask = task?.subtasks.find((candidate) => candidate.id === subtaskId);
    if (!subtask) {
      notify("Subtask not found.", "error");
      return false;
    }
    return runMutation(
      () => subtask.completed ? repository.reopenSubtask(taskId, subtaskId, subtask.version) : repository.completeSubtask(taskId, subtaskId, subtask.version),
      subtask.completed ? "Subtask reopened." : "Subtask completed.",
    );
  }

  function editSubtask(taskId, subtaskId, title) {
    const normalizedTitle = title.trim();
    const subtask = tasks.find((task) => task.id === taskId)?.subtasks.find((candidate) => candidate.id === subtaskId);
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

    if (!await runMutation(() => repository.createTask(body), "Task created.")) return false;
    setActiveFilter(TASK_FILTER_IDS.OPEN);
    setIsCreateDialogOpen(false);
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
    openTaskCount: tasks.filter((task) => !task.completed).length,
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
    upcomingTasks,
    toggleTask,
    toggleSubtask,
    totalCount: summary?.totalCount ?? 0,
  };
}
