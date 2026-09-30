import { API_PATHS } from "@/constants/api_constants.js";
import { apiClient } from "@/services/api_client.js";

export async function updatePreferences(body) {
  const { data } = await apiClient.patch(API_PATHS.PREFERENCES, body);
  return data.data;
}