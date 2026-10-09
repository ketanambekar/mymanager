import { API_PATHS } from "@/constants/api_constants.js";
import { apiClient } from "@/services/api_client.js";

export async function getHabits({ search, projectId, cursor, signal } = {}) {
  const response = await apiClient.get(API_PATHS.HABITS, {
    params: { limit: 50, ...(search ? { search } : {}), ...(projectId ? { projectId } : {}), ...(cursor ? { cursor } : {}) },
    signal,
  });
  return response.data.data;
}

export async function getHabitCalendar(habitId, month, signal) {
  const response = await apiClient.get(`${API_PATHS.HABITS}/${encodeURIComponent(habitId)}/calendar`, {
    params: month ? { month } : {},
    signal,
  });
  return response.data.data;
}

export async function getHabitProjects(signal) {
  const response = await apiClient.get(API_PATHS.PROJECTS, { signal });
  return response.data.data;
}
