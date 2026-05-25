import { apiBaseUrl, fetchJson, postJson } from "./api";
import type {
  CreatePriorityFormValues,
  CreateProjectColorFormValues,
  CreateProjectFormValues,
  CreateProjectTypeFormValues,
  CreateProjectResponse,
  CreateTaskFormValues,
  CreateTaskResponse,
  DashboardApiProjectCollection,
  DashboardApiTaskCollection,
  DashboardSnapshot,
  DeleteMutationResponse,
  MasterMutationResponse,
  MasterCollections,
  ProjectDetail,
  TaskItem,
  TaskDetail,
  TaskStatus,
  UpdatePriorityFormValues,
  UpdateProjectColorFormValues,
  UpdateProjectTypeFormValues,
  UpdateTaskStatusResponse,
} from "@/types/dashboard";

function formatDateLabel(value: string | null): string {
  if (!value) {
    return "No due date";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return "No due date";
  }

  return new Intl.DateTimeFormat("en", {
    month: "short",
    day: "numeric",
  }).format(date);
}

function mapTaskDueText(task: DashboardApiTaskCollection["data"][number]): string {
  if (task.status === "COMPLETED") {
    return "Done";
  }

  if (task.endDateTime) {
    return `Due ${formatDateLabel(task.endDateTime)}`;
  }

  if (task.startDateTime) {
    return `Starts ${formatDateLabel(task.startDateTime)}`;
  }

  return `Created ${formatDateLabel(task.createdAt)}`;
}

function mapTask(task: DashboardApiTaskCollection["data"][number]): TaskItem {
  const subTasks = (task.subtasks ?? []).map((subtask) => ({
    id: subtask.id,
    name: subtask.name,
    status: subtask.status,
  }));

  return {
    id: task.id,
    name: task.name,
    description: task.description,
    projectName: task.project.name,
    status: task.status,
    priority: task.priority.code as TaskItem["priority"],
    dueText: mapTaskDueText(task),
    subTaskCount: subTasks.length,
    subTasks,
  };
}

function priorityOrder(code: string): number {
  const normalized = code.trim().toUpperCase();
  if (/^P\d+$/.test(normalized)) {
    return Number(normalized.slice(1));
  }

  return Number.POSITIVE_INFINITY;
}

export async function loadDashboardSnapshot(): Promise<DashboardSnapshot> {
  const [projectResponse, taskResponse] = await Promise.all([
    fetchJson<DashboardApiProjectCollection>({ path: "/projects" }),
    fetchJson<DashboardApiTaskCollection>({ path: "/tasks" }),
  ]);

  const tasks = taskResponse.data.map(mapTask);
  const taskCountByProjectId = taskResponse.data.reduce<Record<number, number>>((counts, task) => {
    counts[task.projectId] = (counts[task.projectId] ?? 0) + 1;
    return counts;
  }, {});

  const projects = projectResponse.data.map((project) => ({
    id: project.id,
    name: project.name,
    description: project.description ?? "No description yet.",
    status: project.status,
    colorHex: project.color.hexCode,
    priority: project.priority.code,
    taskCount: taskCountByProjectId[project.id] ?? 0,
  }));

  return {
    projects,
    tasks,
    apiBaseUrl,
  };
}

type MasterCollectionResponse<T> = {
  success: true;
  data: T[];
};

export async function loadMasterCollections(): Promise<MasterCollections> {
  const [projectTypesResponse, prioritiesResponse, colorsResponse] = await Promise.all([
    fetchJson<MasterCollectionResponse<{ id: number; name: string; iconUrl: string | null }>>({ path: "/project-types" }),
    fetchJson<MasterCollectionResponse<{ id: number; code: string; title: string }>>({ path: "/priorities" }),
    fetchJson<MasterCollectionResponse<{ id: number; name: string; hexCode: string }>>({ path: "/project-colors" }),
  ]);

  return {
    projectTypes: projectTypesResponse.data.map((item) => ({
      id: item.id,
      label: item.name,
      iconUrl: item.iconUrl,
    })),
    priorities: prioritiesResponse.data
      .map((item) => ({
        id: item.id,
        label: `${item.code} - ${item.title}`,
        code: item.code as TaskItem["priority"],
        title: item.title,
      }))
      .sort((a, b) => {
        const rankDiff = priorityOrder(a.code) - priorityOrder(b.code);
        if (rankDiff !== 0) {
          return rankDiff;
        }

        return a.code.localeCompare(b.code);
      }),
    colors: colorsResponse.data.map((item) => ({
      id: item.id,
      label: item.name,
      hexCode: item.hexCode,
    })),
  };
}

export async function createTask(values: CreateTaskFormValues): Promise<CreateTaskResponse> {
  return postJson<CreateTaskResponse>("/tasks", {
    projectId: values.projectId,
    name: values.name,
    description: values.description?.trim() || null,
    priorityId: values.priorityId,
    frequency: "ONCE",
    alertEnabled: false,
    status: values.status ?? "PENDING",
  });
}

export async function createProject(values: CreateProjectFormValues): Promise<CreateProjectResponse> {
  return postJson<CreateProjectResponse>("/projects", {
    name: values.name,
    description: values.description?.trim() || null,
    typeId: values.typeId,
    colorId: values.colorId,
    priorityId: values.priorityId,
    status: values.status ?? "ACTIVE",
    dpImage: values.dpImage ?? null,
  });
}

export async function loadProjectDetails(projectId: number): Promise<{ project: ProjectDetail; tasks: TaskDetail[] }> {
  const [projectResponse, taskResponse] = await Promise.all([
    fetchJson<{ success: true; data: ProjectDetail }>({ path: `/projects/${projectId}` }),
    fetchJson<{ success: true; data: TaskDetail[] }>({ path: `/tasks/project/${projectId}` }),
  ]);

  return {
    project: projectResponse.data,
    tasks: taskResponse.data,
  };
}

export async function updateProject(
  projectId: number,
  values: {
    name?: string;
    description?: string | null;
    typeId?: number;
    colorId?: number;
    priorityId?: number;
    status?: ProjectDetail["status"];
    dpImage?: string | null;
  },
): Promise<CreateProjectResponse> {
  return fetchJson<CreateProjectResponse>({
    path: `/projects/${projectId}`,
    method: "PUT",
    body: JSON.stringify(values),
  });
}

export async function deleteProject(projectId: number): Promise<DeleteMutationResponse> {
  return fetchJson<DeleteMutationResponse>({
    path: `/projects/${projectId}`,
    method: "DELETE",
  });
}

export async function updateTask(
  taskId: number,
  values: {
    projectId?: number;
    name?: string;
    description?: string | null;
    priorityId?: number;
    status?: TaskStatus;
    frequency?: string;
    alertEnabled?: boolean;
    alertBeforeMinutes?: number | null;
    startDateTime?: string | null;
    endDateTime?: string | null;
    durationMinutes?: number | null;
  },
): Promise<CreateTaskResponse> {
  return fetchJson<CreateTaskResponse>({
    path: `/tasks/${taskId}`,
    method: "PUT",
    body: JSON.stringify(values),
  });
}

export async function deleteTask(taskId: number): Promise<DeleteMutationResponse> {
  return fetchJson<DeleteMutationResponse>({
    path: `/tasks/${taskId}`,
    method: "DELETE",
  });
}

export async function createSubTask(values: {
  taskId: number;
  name: string;
  description?: string;
  status?: TaskStatus;
}): Promise<CreateTaskResponse> {
  return postJson<CreateTaskResponse>("/subtasks", {
    taskId: values.taskId,
    name: values.name.trim(),
    description: values.description?.trim() || null,
    status: values.status ?? "PENDING",
  });
}

export async function updateSubTask(
  subTaskId: number,
  values: {
    name?: string;
    description?: string | null;
    status?: TaskStatus;
  },
): Promise<CreateTaskResponse> {
  return fetchJson<CreateTaskResponse>({
    path: `/subtasks/${subTaskId}`,
    method: "PUT",
    body: JSON.stringify(values),
  });
}

export async function deleteSubTask(subTaskId: number): Promise<DeleteMutationResponse> {
  return fetchJson<DeleteMutationResponse>({
    path: `/subtasks/${subTaskId}`,
    method: "DELETE",
  });
}

export async function updateTaskStatus(taskId: number, status: TaskStatus): Promise<UpdateTaskStatusResponse> {
  return fetchJson<UpdateTaskStatusResponse>({
    path: `/tasks/${taskId}`,
    method: "PUT",
    body: JSON.stringify({ status }),
  });
}

export async function createProjectType(values: CreateProjectTypeFormValues): Promise<MasterMutationResponse> {
  return postJson<MasterMutationResponse>("/project-types", {
    name: values.name.trim(),
    iconUrl: values.iconUrl?.trim() || null,
  });
}

export async function updateProjectType(values: UpdateProjectTypeFormValues): Promise<MasterMutationResponse> {
  return fetchJson<MasterMutationResponse>({
    path: `/project-types/${values.id}`,
    method: "PUT",
    body: JSON.stringify({
      name: values.name.trim(),
      iconUrl: values.iconUrl?.trim() || null,
    }),
  });
}

export async function createPriority(values: CreatePriorityFormValues): Promise<MasterMutationResponse> {
  return postJson<MasterMutationResponse>("/priorities", {
    code: values.code.trim().toUpperCase(),
    title: values.title.trim(),
  });
}

export async function updatePriority(values: UpdatePriorityFormValues): Promise<MasterMutationResponse> {
  return fetchJson<MasterMutationResponse>({
    path: `/priorities/${values.id}`,
    method: "PUT",
    body: JSON.stringify({
      code: values.code.trim().toUpperCase(),
      title: values.title.trim(),
    }),
  });
}

export async function createProjectColor(values: CreateProjectColorFormValues): Promise<MasterMutationResponse> {
  return postJson<MasterMutationResponse>("/project-colors", {
    name: values.name.trim(),
    hexCode: values.hexCode.trim().toUpperCase(),
  });
}

export async function updateProjectColor(values: UpdateProjectColorFormValues): Promise<MasterMutationResponse> {
  return fetchJson<MasterMutationResponse>({
    path: `/project-colors/${values.id}`,
    method: "PUT",
    body: JSON.stringify({
      name: values.name.trim(),
      hexCode: values.hexCode.trim().toUpperCase(),
    }),
  });
}

export async function deleteProjectColor(id: number): Promise<DeleteMutationResponse> {
  return fetchJson<DeleteMutationResponse>({
    path: `/project-colors/${id}`,
    method: "DELETE",
  });
}