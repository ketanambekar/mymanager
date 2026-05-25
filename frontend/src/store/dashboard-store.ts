import { create } from "zustand";
import {
  createPriority,
  createProject,
  createProjectColor,
  createProjectType,
  deleteProjectColor,
  createTask,
  loadDashboardSnapshot,
  loadMasterCollections,
  updatePriority,
  updateProjectColor,
  updateProjectType,
  updateTaskStatus,
} from "@/lib/dashboard-api";
import {
  CreatePriorityFormValues,
  CreateProjectColorFormValues,
  CreateProjectFormValues,
  CreateProjectTypeFormValues,
  CreateTaskFormValues,
  MasterCollections,
  ProjectItem,
  TaskItem,
  TaskStatus,
  UpdatePriorityFormValues,
  UpdateProjectColorFormValues,
  UpdateProjectTypeFormValues,
} from "@/types/dashboard";

async function refreshMasters(): Promise<MasterCollections> {
  return loadMasterCollections();
}

type DashboardState = {
  projects: ProjectItem[];
  tasks: TaskItem[];
  masters: MasterCollections | null;
  selectedProjectId: number | null;
  activePanel: "dashboard" | "projects" | "tasks" | "masters" | "settings";
  isComposerOpen: boolean;
  isProjectComposerOpen: boolean;
  isLoading: boolean;
  error: string | null;
  setSelectedProjectId: (id: number | null) => void;
  setActivePanel: (panel: DashboardState["activePanel"]) => void;
  openComposer: () => void;
  closeComposer: () => void;
  openProjectComposer: () => void;
  closeProjectComposer: () => void;
  loadMasters: () => Promise<void>;
  submitProject: (values: CreateProjectFormValues) => Promise<void>;
  submitTask: (values: CreateTaskFormValues) => Promise<number | null>;
  createProjectTypeMaster: (values: CreateProjectTypeFormValues) => Promise<void>;
  updateProjectTypeMaster: (values: UpdateProjectTypeFormValues) => Promise<void>;
  createPriorityMaster: (values: CreatePriorityFormValues) => Promise<void>;
  updatePriorityMaster: (values: UpdatePriorityFormValues) => Promise<void>;
  createProjectColorMaster: (values: CreateProjectColorFormValues) => Promise<void>;
  updateProjectColorMaster: (values: UpdateProjectColorFormValues) => Promise<void>;
  deleteProjectColorMaster: (id: number) => Promise<void>;
  setTaskStatus: (taskId: number, status: TaskStatus) => Promise<void>;
  loadDashboard: () => Promise<void>;
};

export const useDashboardStore = create<DashboardState>((set, get) => ({
  projects: [],
  tasks: [],
  masters: null,
  selectedProjectId: null,
  activePanel: "dashboard",
  isComposerOpen: false,
  isProjectComposerOpen: false,
  isLoading: false,
  error: null,
  setSelectedProjectId: (id) => set({ selectedProjectId: id }),
  setActivePanel: (panel) => set({ activePanel: panel }),
  openComposer: () => set({ isComposerOpen: true, isProjectComposerOpen: false, error: null }),
  closeComposer: () => set({ isComposerOpen: false }),
  openProjectComposer: () => set({ isProjectComposerOpen: true, isComposerOpen: false, error: null }),
  closeProjectComposer: () => set({ isProjectComposerOpen: false }),
  loadMasters: async () => {
    if (get().masters) {
      return;
    }

    try {
      const masters = await loadMasterCollections();
      set({ masters });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : "Unable to load master data.",
      });
    }
  },
  submitProject: async (values) => {
    set({ isLoading: true, error: null });

    try {
      await createProject(values);
      const [snapshot, masters] = await Promise.all([loadDashboardSnapshot(), refreshMasters()]);
      const createdProject = snapshot.projects.at(-1) ?? null;
      set({
        projects: snapshot.projects,
        tasks: snapshot.tasks,
        masters,
        isLoading: false,
        isProjectComposerOpen: false,
        activePanel: "projects",
        selectedProjectId: createdProject?.id ?? null,
      });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to create project.",
      });
    }
  },
  submitTask: async (values) => {
    set({ isLoading: true, error: null });

    try {
      const createdTask = await createTask(values);
      const [snapshot, masters] = await Promise.all([loadDashboardSnapshot(), refreshMasters()]);
      set({
        projects: snapshot.projects,
        tasks: snapshot.tasks,
        masters,
        isLoading: false,
        isComposerOpen: false,
        isProjectComposerOpen: false,
        activePanel: "tasks",
        selectedProjectId: null,
      });
      return createdTask.data.id;
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to create task.",
      });
      return null;
    }
  },
  setTaskStatus: async (taskId, status) => {
    const previousTasks = get().tasks;
    set((state) => ({
      isLoading: true,
      error: null,
      tasks: state.tasks.map((task) => (task.id === taskId ? { ...task, status } : task)),
    }));

    try {
      await updateTaskStatus(taskId, status);
      const snapshot = await loadDashboardSnapshot();
      set({
        projects: snapshot.projects,
        tasks: snapshot.tasks,
        isLoading: false,
        error: null,
      });
    } catch (error) {
      set({
        isLoading: false,
        tasks: previousTasks,
        error: error instanceof Error ? error.message : "Unable to update task status.",
      });
    }
  },
  createProjectTypeMaster: async (values) => {
    set({ isLoading: true, error: null });

    try {
      await createProjectType(values);
      const masters = await refreshMasters();
      set({ masters, isLoading: false, activePanel: "masters" });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to create project type.",
      });
    }
  },
  updateProjectTypeMaster: async (values) => {
    set({ isLoading: true, error: null });

    try {
      await updateProjectType(values);
      const masters = await refreshMasters();
      set({ masters, isLoading: false, activePanel: "masters" });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to update project type.",
      });
    }
  },
  createPriorityMaster: async (values) => {
    set({ isLoading: true, error: null });

    try {
      await createPriority(values);
      const masters = await refreshMasters();
      set({ masters, isLoading: false, activePanel: "masters" });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to create priority.",
      });
    }
  },
  updatePriorityMaster: async (values) => {
    set({ isLoading: true, error: null });

    try {
      await updatePriority(values);
      const masters = await refreshMasters();
      set({ masters, isLoading: false, activePanel: "masters" });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to update priority.",
      });
    }
  },
  createProjectColorMaster: async (values) => {
    set({ isLoading: true, error: null });

    try {
      await createProjectColor(values);
      const masters = await refreshMasters();
      set({ masters, isLoading: false, activePanel: "masters" });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to create project color.",
      });
    }
  },
  updateProjectColorMaster: async (values) => {
    set({ isLoading: true, error: null });

    try {
      await updateProjectColor(values);
      const masters = await refreshMasters();
      set({ masters, isLoading: false, activePanel: "masters" });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to update project color.",
      });
    }
  },
  deleteProjectColorMaster: async (id) => {
    set({ isLoading: true, error: null });

    try {
      await deleteProjectColor(id);
      const masters = await refreshMasters();
      set({ masters, isLoading: false, activePanel: "masters" });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to delete project color.",
      });
    }
  },
  loadDashboard: async () => {
    if (get().isLoading) {
      return;
    }

    set({ isLoading: true, error: null });

    try {
      const [snapshot, masters] = await Promise.all([loadDashboardSnapshot(), refreshMasters()]);
      set({
        projects: snapshot.projects,
        tasks: snapshot.tasks,
        masters,
        isLoading: false,
        error: null,
      });
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : "Unable to load dashboard data.",
      });
    }
  },
}));
