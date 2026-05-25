const DEFAULT_BASE_URL = "http://localhost:5000/api/v1";

export const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? DEFAULT_BASE_URL;

function resolveApiBaseUrl(): string {
  const configuredBaseUrl = apiBaseUrl;

  if (typeof window === "undefined") {
    return configuredBaseUrl;
  }

  try {
    const configuredUrl = new URL(configuredBaseUrl);
    const currentHost = window.location.hostname;

    // Keep auth cookies first-party by using the same host family as the frontend.
    if (currentHost === "localhost" && configuredUrl.hostname !== "localhost") {
      configuredUrl.hostname = "localhost";
      return configuredUrl.toString();
    }

    if (currentHost !== "localhost" && configuredUrl.hostname === "localhost") {
      configuredUrl.hostname = currentHost;
      return configuredUrl.toString();
    }

    return configuredBaseUrl;
  } catch {
    return configuredBaseUrl;
  }
}

let accessToken: string | null = null;
let refreshHandler: null | (() => Promise<string | null>) = null;

type RequestOptions = RequestInit & {
  path: string;
  skipAuthRetry?: boolean;
};

export function setAccessToken(token: string | null): void {
  accessToken = token;
}

export function setRefreshHandler(handler: (() => Promise<string | null>) | null): void {
  refreshHandler = handler;
}

async function executeRequest(path: string, options: RequestInit): Promise<Response> {
  const runtimeBaseUrl = resolveApiBaseUrl();
  const normalizedBaseUrl = apiBaseUrl.endsWith("/") ? apiBaseUrl : `${apiBaseUrl}/`;
  const normalizedPath = path.replace(/^\/+/, "");

  const normalizedRuntimeBaseUrl = runtimeBaseUrl.endsWith("/") ? runtimeBaseUrl : `${runtimeBaseUrl}/`;

  return fetch(new URL(normalizedPath, normalizedRuntimeBaseUrl).toString(), {
    ...options,
    credentials: "include",
  });
}

export async function fetchJson<T>({ path, headers, skipAuthRetry, ...options }: RequestOptions): Promise<T> {
  let finalHeaders: HeadersInit = {
    "Content-Type": "application/json",
    ...headers,
  };

  if (accessToken) {
    finalHeaders = {
      ...finalHeaders,
      Authorization: `Bearer ${accessToken}`,
    };
  }

  let response = await executeRequest(path, {
    ...options,
    headers: finalHeaders,
  });

  if (response.status === 401 && !skipAuthRetry && refreshHandler) {
    const refreshedAccessToken = await refreshHandler();

    if (refreshedAccessToken) {
      const retryHeaders: HeadersInit = {
        ...finalHeaders,
        Authorization: `Bearer ${refreshedAccessToken}`,
      };

      response = await executeRequest(path, {
        ...options,
        headers: retryHeaders,
      });
    }
  }

  if (!response.ok) {
    const errorText = await response.text();

    if (errorText) {
      try {
        const parsed = JSON.parse(errorText) as { message?: string };
        throw new Error(parsed.message || errorText);
      } catch {
        throw new Error(errorText);
      }
    }

    throw new Error(`Request failed with status ${response.status}`);
  }

  return (await response.json()) as T;
}

export async function postJson<T>(path: string, body: unknown): Promise<T> {
  return fetchJson<T>({
    path,
    method: "POST",
    body: JSON.stringify(body),
  });
}