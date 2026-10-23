import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { api, errorText } from "../../api";
import { useAuth } from "../../auth/AuthProvider";
import { useToast } from "../ToastProvider";
import { useDashboard, useRefreshDashboard } from "../../hooks/useDashboard";
import type { Incident, Report, ResponseTask } from "../../types";
import { AuditPanel } from "./AuditPanel";
import { IncidentsPanel } from "./IncidentsPanel";
import { ReportsPanel } from "./ReportsPanel";
import { TasksPanel } from "./TasksPanel";
import { UsersPanel } from "./UsersPanel";
import { WorkspaceDialogs, type WorkspaceDialog } from "./WorkspaceDialogs";

type WorkspaceTab = "reports" | "incidents" | "tasks" | "audit" | "users";

/** Present live metrics and role-authorized operational tools. */
export function Workspace() {
  const { profile, session } = useAuth();
  const { data, isPending, error, refetch } = useDashboard();
  const refresh = useRefreshDashboard();
  const { notify } = useToast();
  const worker = useMutation({
    mutationFn: () => api<{ processed: boolean; report_id?: string; validation?: string }>("/api/v1/worker/run-once", session?.access_token, { method: "POST" }),
    onSuccess: (result) => {
      notify(result.processed ? "Worker processed report " + (result.report_id ?? "").slice(0, 8) + " (" + (result.validation ?? "complete") + ")." : "Queue is empty.", result.processed ? "success" : "info");
      refresh();
    },
    onError: (reason) => notify("Worker failed: " + errorText(reason), "error"),
  });
  const [tab, setTab] = useState<WorkspaceTab>("reports");
  const [dialog, setDialog] = useState<WorkspaceDialog | null>(null);
  const isCoordinator = profile?.role === "coordinator";

  if (isPending) return <div className="card access-state-card" role="status"><h2>Loading operational data…</h2></div>;
  if (error || !data) return (
    <div className="card access-state-card" role="alert">
      <h2>Workspace data could not be loaded</h2>
      <p>{errorText(error)}</p>
      <button className="button button-outline button-sm" type="button" onClick={() => void refetch()}>Retry</button>
    </div>
  );

  const reportCount = data.reports.length;
  const incidentCount = data.incidents.length;
  const taskCount = data.tasks.length;
  const tabItems: { id: WorkspaceTab; label: string; count?: number }[] = [
    { id: "reports", label: "Incoming Reports", count: reportCount },
    { id: "incidents", label: "Incidents", count: incidentCount },
    { id: "tasks", label: "Response Tasks", count: taskCount },
    ...(isCoordinator ? [{ id: "audit" as const, label: "Security Audit Log" }, { id: "users" as const, label: "Account Access" }] : []),
  ];
  const reports: Report[] = data.reports;
  const incidents: Incident[] = data.incidents;
  const tasks: ResponseTask[] = data.tasks;

  return (
    <section className="workspace-panel" aria-label="Operational workspace">
      {isCoordinator && <div className="panel-toolbar"><p className="panel-subtitle">Run one queued report through the configured extraction pipeline.</p><button className="button button-action button-sm" type="button" disabled={worker.isPending} onClick={() => worker.mutate()}>{worker.isPending ? "Processing…" : "⚡ Run Queue Worker"}</button></div>}
      <div className="metrics-grid" aria-label="Operational metrics">
        <Metric label="Incoming Reports" value={data.summary.reports} hint="Durable intake" />
        <Metric label="Awaiting Review" value={data.summary.needs_review} hint="Coordinator action" className="alert-metric" />
        <Metric label="Open Incidents" value={data.summary.open_incidents} hint="Active situations" className="active-metric" />
        <Metric label="Active Tasks" value={data.summary.active_tasks} hint="In progress or assigned" className="task-metric" />
      </div>
      <div className="workspace-tabs" role="tablist" aria-label="Operational sections">
        {tabItems.map((item) => (
          <button
            key={item.id}
            id={"tab-" + item.id}
            className={"tab-btn" + (tab === item.id ? " active" : "")}
            type="button"
            role="tab"
            aria-selected={tab === item.id}
            aria-controls={"panel-" + item.id}
            onClick={() => setTab(item.id)}
          >
            {item.label}{item.count !== undefined && <span className="tab-badge">{item.count}</span>}
          </button>
        ))}
      </div>
      <div id="panel-reports" className="tab-panel active" role="tabpanel" aria-labelledby="tab-reports" hidden={tab !== "reports"}>
        <ReportsPanel reports={reports} token={session?.access_token ?? null} role={profile?.role ?? "pending"} onChanged={refresh} onCreateIncident={(report) => setDialog({ type: "incident", report })} onInspect={(report) => setDialog({ type: "report", report })} />
      </div>
      <div id="panel-incidents" className="tab-panel active" role="tabpanel" aria-labelledby="tab-incidents" hidden={tab !== "incidents"}>
        <IncidentsPanel incidents={incidents} role={profile?.role ?? "pending"} onRefresh={refresh} onCreate={() => setDialog({ type: "incident" })} onPropose={(incident) => setDialog({ type: "task", incident })} />
      </div>
      <div id="panel-tasks" className="tab-panel active" role="tabpanel" aria-labelledby="tab-tasks" hidden={tab !== "tasks"}>
        <TasksPanel tasks={tasks} role={profile?.role ?? "pending"} onRefresh={refresh} onAssign={(task) => setDialog({ type: "assign", task })} />
      </div>
      {isCoordinator && (
        <>
          <div id="panel-audit" className="tab-panel active" role="tabpanel" aria-labelledby="tab-audit" hidden={tab !== "audit"}><AuditPanel token={session?.access_token ?? null} /></div>
          <div id="panel-users" className="tab-panel active" role="tabpanel" aria-labelledby="tab-users" hidden={tab !== "users"}><UsersPanel token={session?.access_token ?? null} currentEmail={profile?.email ?? ""} /></div>
        </>
      )}
      <WorkspaceDialogs dialog={dialog} close={() => setDialog(null)} token={session?.access_token ?? null} onChanged={refresh} />
    </section>
  );
}

function Metric({ label, value, hint, className = "" }: { label: string; value: number; hint: string; className?: string }) {
  return <div className={"metric-card " + className}><span className="metric-label">{label}</span><strong className="metric-value">{value}</strong><span className="metric-sub">{hint}</span></div>;
}
