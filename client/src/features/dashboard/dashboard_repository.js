import { API_PATHS } from "@/constants/api_constants.js";
import { apiClient } from "@/services/api_client.js";

const resource = async (request) => (await request).data.data;
const taskPath = (taskId) => `${API_PATHS.TASKS}/${taskId}`;
const subtaskPath = (taskId, subtaskId) => `${taskPath(taskId)}/subtasks/${subtaskId}`;

export const getDashboard = () => resource(apiClient.get(API_PATHS.DASHBOARD));

export async function getTaskList({ status = "all", projectId, search, dateScope = "recent" } = {}) {
  const items = [];
  let cursor = null;
  do {
    const page = await resource(apiClient.get(API_PATHS.TASKS, { params: { status, projectId, search, dateScope, limit: 100, ...(cursor ? { cursor } : {}) } }));
    items.push(...page.items);
    cursor = page.nextCursor;
  } while (cursor);
  return items;
}

export const getProject = (projectId) => resource(apiClient.get(`${API_PATHS.PROJECTS}/${projectId}`));
export const createProject = (project) => resource(apiClient.post(API_PATHS.PROJECTS, project));
export const updateProject = (projectId, project) => resource(apiClient.patch(`${API_PATHS.PROJECTS}/${projectId}`, project));
export const deleteProject = (projectId) => resource(apiClient.delete(`${API_PATHS.PROJECTS}/${projectId}`));

export const createTask = (task) => resource(apiClient.post(API_PATHS.TASKS, task));
export const getTask = (taskId) => resource(apiClient.get(taskPath(taskId)));
export const updateTask = (taskId, task) => resource(apiClient.patch(taskPath(taskId), task));
export const deleteTask = (taskId) => resource(apiClient.delete(taskPath(taskId)));
export const completeTask = (taskId, version) => resource(apiClient.post(`${taskPath(taskId)}/complete`, { version }));
export const reopenTask = (taskId, version) => resource(apiClient.post(`${taskPath(taskId)}/reopen`, { version }));
export const skipTask = (taskId, version, reason) => resource(apiClient.post(`${taskPath(taskId)}/skip`, { version, reason }));
export const missTask = (taskId, version, reason) => resource(apiClient.post(`${taskPath(taskId)}/miss`, { version, reason }));

export const createSubtask = (taskId, title) => resource(apiClient.post(`${taskPath(taskId)}/subtasks`, { title }));
export const updateSubtask = (taskId, subtaskId, title, version) => resource(apiClient.patch(subtaskPath(taskId, subtaskId), { title, version }));
export const deleteSubtask = (taskId, subtaskId) => resource(apiClient.delete(subtaskPath(taskId, subtaskId)));
export const completeSubtask = (taskId, subtaskId, version) => resource(apiClient.post(`${subtaskPath(taskId, subtaskId)}/complete`, { version }));
export const reopenSubtask = (taskId, subtaskId, version) => resource(apiClient.post(`${subtaskPath(taskId, subtaskId)}/reopen`, { version }));
