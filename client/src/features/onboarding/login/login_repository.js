import { API_PATHS } from "@/constants/api_constants.js";
import { apiClient } from "@/services/api_client.js";

export async function loginWithGoogleCredential(credential) {
  const { data } = await apiClient.post(API_PATHS.GOOGLE_LOGIN, { credential }, { skipAuthRefresh: true });
  return data.data;
}

export async function getSession() {
  const { data } = await apiClient.get(API_PATHS.SESSION);
  return data.data;
}

export async function logoutSession() {
  await apiClient.post(API_PATHS.LOGOUT, null, { skipAuthRefresh: true });
}