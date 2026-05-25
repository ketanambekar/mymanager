export type PriorityLevel = "P1" | "P2" | "P3" | "P4";

export type TaskStatus = "ACTIVE" | "IN_PROGRESS" | "COMPLETED" | "HOLD" | "IN_REVIEW" | "PENDING";

export type ProjectItem = {
  id: number;
  name: string;
  description: string;
  status: "ACTIVE" | "HOLD" | "COMPLETED" | "ARCHIVED";
  colorHex: string;
  priority: PriorityLevel;
  taskCount: number;
};

export type TaskItem = {
  id: number;
  name: string;
  description: string | null;
  projectName: string;
  status: TaskStatus;
  priority: PriorityLevel;
  dueText: string;
  subTaskCount: number;
  subTasks: Array<{
    id: number;
    name: string;
    status: TaskStatus;
  }>;
};

export type MasterItem = {
  id: number;
  label: string;
};

export type MasterCollections = {
  projectTypes: Array<MasterItem & { iconUrl: string | null }>;
  priorities: Array<MasterItem & { code: PriorityLevel; title: string }>;
  colors: Array<MasterItem & { hexCode: string }>;
};

export type DashboardApiProjectCollection = {
  success: true;
  data: Array<{
    id: number;
    name: string;
    description: string | null;
    status: "ACTIVE" | "HOLD" | "COMPLETED" | "ARCHIVED";
    color: {
      hexCode: string;
    };
    priority: {
      code: PriorityLevel;
    };
  }>;
};

export type DashboardApiTaskCollection = {
  success: true;
  data: Array<{
    id: number;
    projectId: number;
    name: string;
    description: string | null;
    status: TaskItem["status"];
    priority: {
      code: PriorityLevel;
    };
    project: {
      name: string;
    };
    subtasks?: Array<{ id: number; name: string; status: TaskStatus }>;
    startDateTime: string | null;
    endDateTime: string | null;
    createdAt: string;
  }>;
};

export type DashboardSnapshot = {
  projects: ProjectItem[];
  tasks: TaskItem[];
  apiBaseUrl: string;
};

export type ProjectDetail = {
  id: number;
  name: string;
  description: string | null;
  status: ProjectItem["status"];
  typeId: number;
  colorId: number;
  priorityId: number;
  dpImage: string | null;
  createdAt: string;
  updatedAt: string;
  type: {
    id: number;
    name: string;
    iconUrl?: string | null;
  };
  color: {
    id: number;
    name: string;
    hexCode: string;
  };
  priority: {
    id: number;
    code: PriorityLevel;
    title: string;
  };
};

export type TaskDetail = {
  id: number;
  projectId: number;
  name: string;
  description: string | null;
  priorityId: number;
  frequency: string;
  alertEnabled: boolean;
  alertBeforeMinutes: number | null;
  startDateTime: string | null;
  endDateTime: string | null;
  durationMinutes: number | null;
  status: TaskStatus;
  createdAt: string;
  updatedAt: string;
  project: {
    id: number;
    name: string;
  };
  priority: {
    id: number;
    code: PriorityLevel;
    title: string;
  };
  subtasks: Array<{
    id: number;
    name: string;
    description: string | null;
    status: TaskStatus;
    createdAt: string;
    updatedAt: string;
  }>;
};

export type CreateTaskFormValues = {
  projectId: number;
  name: string;
  description?: string;
  priorityId: number;
  status?: TaskStatus;
};

export type CreateProjectFormValues = {
  name: string;
  description?: string;
  typeId: number;
  colorId: number;
  priorityId: number;
  status?: ProjectItem["status"];
  dpImage?: string | null;
};

export type CreateTaskResponse = {
  success: true;
  data: {
    id: number;
    [key: string]: unknown;
  };
};

export type CreateProjectResponse = {
  success: true;
  data: unknown;
};

export type UpdateTaskStatusResponse = {
  success: true;
  data: unknown;
};

export type DeleteMutationResponse = {
  success: true;
  message?: string;
};

export type CreateProjectTypeFormValues = {
  name: string;
  iconUrl?: string | null;
};

export type UpdateProjectTypeFormValues = {
  id: number;
  name: string;
  iconUrl?: string | null;
};

export type CreatePriorityFormValues = {
  code: string;
  title: string;
};

export type UpdatePriorityFormValues = {
  id: number;
  code: string;
  title: string;
};

export type CreateProjectColorFormValues = {
  name: string;
  hexCode: string;
};

export type UpdateProjectColorFormValues = {
  id: number;
  name: string;
  hexCode: string;
};

export type MasterMutationResponse = {
  success: true;
  data: unknown;
};
