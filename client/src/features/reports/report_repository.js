import { API_PATHS } from "@/constants/api_constants.js";
import { apiClient } from "@/services/api_client.js";

export async function getReport(year = null, signal) {
  const response = await apiClient.get(API_PATHS.REPORTS, {
    params: year === null ? {} : { year },
    signal,
  });
  return response.data.data;
}
