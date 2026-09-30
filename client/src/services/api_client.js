import axios from "axios";
import { API_PATHS } from "@/constants/api_constants.js";

const baseURL = import.meta.env.VITE_API_BASE_URL;
export const apiClient = axios.create({ baseURL, withCredentials: true });
let accessToken = null;
let onSessionExpired = () => {};
let refreshPromise = null;

export function setAccessToken(token) {
  accessToken = token;
}

export function setSessionExpiredHandler(handler) {
  onSessionExpired = handler;
}

export function getApiErrorMessage(error) {
  return error.response?.data?.error?.message ?? error.response?.data?.message ?? error.message ?? "Request failed. Please try again.";
}

export function isVersionConflict(error) {
  return error.response?.status === 409 && ["VERSION_CONFLICT", "SUBTASK_NOT_FOUND_OR_CHANGED"].includes(error.response?.data?.error?.code);
}

export async function refreshSession() {
  if (!refreshPromise) {
    refreshPromise = apiClient.post(API_PATHS.REFRESH, null, { skipAuthRefresh: true })
      .then(({ data }) => {
        accessToken = data.data.accessToken;
        return data.data;
      })
      .finally(() => { refreshPromise = null; });
  }
  return refreshPromise;
}

apiClient.interceptors.request.use((config) => {
  if (!baseURL) throw new Error("VITE_API_BASE_URL is not configured.");
  if (accessToken && !config.skipAuthRefresh) config.headers.Authorization = `Bearer ${accessToken}`;
  return config;
});

apiClient.interceptors.response.use((response) => response, async (error) => {
  const config = error.config;
  if (error.response?.status !== 401 || !config || config.skipAuthRefresh || config._retried || config.url === API_PATHS.GOOGLE_LOGIN) {
    return Promise.reject(error);
  }
  config._retried = true;
  try {
    await refreshSession();
    config.headers.Authorization = `Bearer ${accessToken}`;
    return apiClient(config);
  } catch (refreshError) {
    accessToken = null;
    onSessionExpired();
    return Promise.reject(refreshError);
  }
});