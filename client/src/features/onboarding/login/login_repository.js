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

export async function createQrChallenge() {
  const { data } = await apiClient.post(API_PATHS.QR_CHALLENGES, {}, { skipAuthRefresh: true });
  return data.data;
}

export async function getQrChallengeStatus(challengeId, pollToken) {
  const { data } = await apiClient.post(
    `${API_PATHS.QR_CHALLENGES}/${challengeId}/status`,
    { pollToken },
    { skipAuthRefresh: true },
  );
  return data.data;
}

export async function consumeQrChallenge(challengeId, pollToken) {
  const { data } = await apiClient.post(
    `${API_PATHS.QR_CHALLENGES}/${challengeId}/consume`,
    { pollToken },
    { skipAuthRefresh: true },
  );
  return data.data;
}

export async function cancelQrChallenge(challengeId, pollToken) {
  const { data } = await apiClient.post(
    `${API_PATHS.QR_CHALLENGES}/${challengeId}/cancel`,
    { pollToken },
    { skipAuthRefresh: true },
  );
  return data.data;
}