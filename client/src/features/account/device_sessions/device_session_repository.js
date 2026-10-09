import { API_PATHS } from "@/constants/api_constants.js";
import { apiClient } from "@/services/api_client.js";

export async function getDeviceSessions() {
  const { data } = await apiClient.get(API_PATHS.DEVICES);
  return data.data;
}

export async function revokeDeviceSession(deviceId) {
  const { data } = await apiClient.delete(`${API_PATHS.DEVICES}/${encodeURIComponent(deviceId)}`);
  return data.data;
}

export async function lookupQrLogin(code) {
  const { data } = await apiClient.post(API_PATHS.QR_LOOKUP, { code });
  return data.data;
}

export async function decideQrLogin(challengeId, code, decision) {
  const { data } = await apiClient.post(`${API_PATHS.QR_CHALLENGES}/${challengeId}/decision`, { code, decision });
  return data.data;
}
