export class ApiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
    this.name = "ApiError";
  }
}

export const API_BASE_URL: string =
  (import.meta as unknown as { env?: { VITE_API_BASE_URL?: string } }).env?.VITE_API_BASE_URL || "";

/** Fetch a JSON endpoint and surface the server's safe error detail. */
export async function api<T>(
  path: string,
  token?: string | null,
  init: RequestInit = {},
): Promise<T> {
  const headers = new Headers(init.headers);
  if (init.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  if (token) headers.set("Authorization", "Bearer " + token);
  const targetUrl = path.startsWith("http://") || path.startsWith("https://")
    ? path
    : `${API_BASE_URL}${path.startsWith("/") ? path : `/${path}`}`;
  const response = await fetch(targetUrl, { ...init, headers });
  const body: unknown = await response.json().catch(() => null);
  if (!response.ok) {
    const detail =
      body && typeof body === "object" && "detail" in body
        ? String(body.detail)
        : "Request failed (" + response.status + ")";
    throw new ApiError(detail, response.status);
  }
  return body as T;
}

/** Convert unknown failures into readable UI messages. */
export function errorText(error: unknown): string {
  return error instanceof Error ? error.message : "An unexpected error occurred.";
}

/** Return an idempotency key for a single report submission attempt. */
export function reportRequestKey(): string {
  return "web-" + Date.now() + "-" + Math.random().toString(36).slice(2, 9);
}
