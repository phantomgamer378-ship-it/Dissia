import { useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../api";
import { useAuth } from "../auth/AuthProvider";
import type { DashboardSummary, Incident, Report, ResponseTask } from "../types";

export interface DashboardData {
  summary: DashboardSummary;
  reports: Report[];
  incidents: Incident[];
  tasks: ResponseTask[];
}

/** Fetch database-backed workspace metrics and records for the current user. */
export function useDashboard() {
  const { session, profile } = useAuth();
  const token = session?.access_token;
  return useQuery({
    queryKey: ["workspace", profile?.id, profile?.role],
    enabled: Boolean(token && profile && profile.role !== "pending"),
    queryFn: async (): Promise<DashboardData> => {
      const [summary, reports, incidents, tasks] = await Promise.all([
        api<DashboardSummary>("/api/v1/dashboard/summary", token),
        api<{ items: Report[] }>("/api/v1/reports?limit=100", token),
        api<{ items: Incident[] }>("/api/v1/incidents", token),
        api<{ items: ResponseTask[] }>("/api/v1/tasks", token),
      ]);
      return {
        summary,
        reports: reports.items,
        incidents: incidents.items,
        tasks: tasks.items,
      };
    },
  });
}

/** Invalidate current user's operational data after a successful mutation. */
export function useRefreshDashboard() {
  const queryClient = useQueryClient();
  const { profile } = useAuth();
  return () => queryClient.invalidateQueries({ queryKey: ["workspace", profile?.id] });
}
