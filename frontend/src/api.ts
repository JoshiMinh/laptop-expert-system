import type { Laptop, RecommendRequest, RecommendationResponse } from "@shared/types";

const API_BASE_URL = import.meta.env.VITE_API_URL ?? "http://127.0.0.1:8000";

async function requestJson<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
    ...init,
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(message || `Request failed with status ${response.status}`);
  }

  return response.json() as Promise<T>;
}

export function fetchRecommendations(payload: RecommendRequest): Promise<RecommendationResponse> {
  return requestJson<RecommendationResponse>("/recommend", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function fetchLaptops(): Promise<Laptop[]> {
  return requestJson<Laptop[]>("/laptops");
}
