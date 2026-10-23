import { useEffect, useRef, type FormEvent, type ReactNode } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { api, errorText } from "../../api";
import { useAuth } from "../../auth/AuthProvider";
import { useToast } from "../ToastProvider";
import type { ExtractionRecord, Incident, Report, ResponseTask } from "../../types";

export type WorkspaceDialog =
  | { type: "incident"; report?: Report }
  | { type: "task"; incident: Incident }
  | { type: "assign"; task: ResponseTask }
  | { type: "report"; report: Report };

interface WorkspaceDialogsProps {
  dialog: WorkspaceDialog | null;
  close: () => void;
  token: string | null;
  onChanged: () => void;
}

/** Select and render the requested accessible workspace dialog. */
export function WorkspaceDialogs({ dialog, close, token, onChanged }: WorkspaceDialogsProps) {
  if (!dialog) return null;
  const key = dialog.type === "incident" ? "incident" : dialog.type;
  return (
    <DialogFrame key={key} open title={dialogTitle(dialog)} onClose={close}>
      {dialog.type === "incident" && <CreateIncidentForm report={dialog.report} token={token} onClose={close} onChanged={onChanged} />}
      {dialog.type === "task" && <ProposeTaskForm incident={dialog.incident} token={token} onClose={close} onChanged={onChanged} />}
      {dialog.type === "assign" && <AssignTaskForm task={dialog.task} token={token} onClose={close} onChanged={onChanged} />}
      {dialog.type === "report" && <ReportDetails report={dialog.report} token={token} onClose={close} onChanged={onChanged} />}
    </DialogFrame>
  );
}

function DialogFrame({ open, title, onClose, children, large = false }: {
  open: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
  large?: boolean;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) dialog.showModal();
    if (!open && dialog.open) dialog.close();
  }, [open]);
  return (
    <dialog ref={ref} className={"app-dialog" + (large ? " modal-lg" : "")} aria-labelledby="workspace-dialog-title" onCancel={(event) => { event.preventDefault(); onClose(); }} onClose={onClose}>
      <div className="dialog-card">
        <div className="dialog-header"><h2 id="workspace-dialog-title">{title}</h2><button className="dialog-close-btn" type="button" aria-label="Close dialog" onClick={onClose}>×</button></div>
        {children}
      </div>
    </dialog>
  );
}

function CreateIncidentForm({ report, token, onClose, onChanged }: {
  report?: Report;
  token: string | null;
  onClose: () => void;
  onChanged: () => void;
}) {
  const { notify } = useToast();
  const create = useMutation({
    mutationFn: (values: { title: string; location: string | null; summary: string; report_id: string | null }) =>
      api("/api/v1/incidents", token, { method: "POST", body: JSON.stringify(values) }),
    onSuccess: () => { notify("Incident created.", "success"); onChanged(); onClose(); },
    onError: (error) => notify(errorText(error), "error"),
  });
  return (
    <form className="dialog-form" onSubmit={(event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      const values = new FormData(event.currentTarget);
      create.mutate({
        title: String(values.get("title") ?? "").trim(),
        location: String(values.get("location") ?? "").trim() || null,
        summary: String(values.get("summary") ?? "").trim(),
        report_id: report?.id ?? null,
      });
    }}>
      <div className="form-group"><label htmlFor="incident-title">Incident title <span className="required">*</span></label><input id="incident-title" name="title" required minLength={4} maxLength={160} defaultValue={report ? (report.extraction?.incident_category ?? "Reported") + " Emergency" : ""} placeholder="e.g. Major flooding on North Bypass Road" /></div>
      <div className="form-group"><label htmlFor="incident-location">Verified location</label><input id="incident-location" name="location" maxLength={300} defaultValue={report?.location ?? ""} placeholder="Street, landmark, or verified location" /></div>
      <div className="form-group"><label htmlFor="incident-summary">Incident summary <span className="required">*</span></label><textarea id="incident-summary" name="summary" rows={4} required minLength={8} maxLength={2000} defaultValue={report?.description.slice(0, 400) ?? ""} placeholder="Consolidated operational summary of the verified event and key hazards..." /></div>
      <DialogActions onClose={onClose}><button className="button button-primary" type="submit" disabled={create.isPending}>{create.isPending ? "Creating…" : "Confirm & Create Incident"}</button></DialogActions>
    </form>
  );
}

function ProposeTaskForm({ incident, token, onClose, onChanged }: {
  incident: Incident;
  token: string | null;
  onClose: () => void;
  onChanged: () => void;
}) {
  const { notify } = useToast();
  const create = useMutation({
    mutationFn: (values: { title: string; description: string }) =>
      api("/api/v1/incidents/" + incident.id + "/tasks", token, { method: "POST", body: JSON.stringify(values) }),
    onSuccess: () => { notify("Task proposed for coordinator review.", "success"); onChanged(); onClose(); },
    onError: (error) => notify(errorText(error), "error"),
  });
  return (
    <form className="dialog-form" onSubmit={(event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      const values = new FormData(event.currentTarget);
      create.mutate({ title: String(values.get("title") ?? "").trim(), description: String(values.get("description") ?? "").trim() });
    }}>
      <p className="item-meta">Incident: <strong>{incident.title}</strong></p>
      <div className="form-group"><label htmlFor="task-title">Task title <span className="required">*</span></label><input id="task-title" name="title" required minLength={4} maxLength={160} placeholder="e.g. Deploy sandbags and diversion channel" /></div>
      <div className="form-group"><label htmlFor="task-description">Task description and requirements <span className="required">*</span></label><textarea id="task-description" name="description" rows={3} required minLength={5} maxLength={1000} placeholder="Specify actions, resource requirements, safety instructions, and reporting points..." /></div>
      <DialogActions onClose={onClose}><button className="button button-primary" type="submit" disabled={create.isPending}>{create.isPending ? "Submitting…" : "Propose Task"}</button></DialogActions>
    </form>
  );
}

function AssignTaskForm({ task, token, onClose, onChanged }: {
  task: ResponseTask;
  token: string | null;
  onClose: () => void;
  onChanged: () => void;
}) {
  const { notify } = useToast();
  const assign = useMutation({
    mutationFn: (assignee: string) =>
      api("/api/v1/tasks/" + task.id, token, {
        method: "PATCH",
        body: JSON.stringify({ status: "ASSIGNED", assignee, version: task.version }),
      }),
    onSuccess: (_, assignee) => { notify("Task assigned to " + assignee + ".", "success"); onChanged(); onClose(); },
    onError: (error) => notify(errorText(error), "error"),
  });
  return (
    <form className="dialog-form" onSubmit={(event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      const values = new FormData(event.currentTarget);
      assign.mutate(String(values.get("assignee") ?? "").trim());
    }}>
      <p className="item-meta">Task: <strong>{task.title}</strong></p>
      <div className="form-group"><label htmlFor="task-assignee">Assignee name or unit <span className="required">*</span></label><input id="task-assignee" name="assignee" required maxLength={120} placeholder="e.g. Rapid Water Rescue Team Bravo" /></div>
      <DialogActions onClose={onClose}><button className="button button-primary" type="submit" disabled={assign.isPending}>{assign.isPending ? "Assigning…" : "Authorize & Assign"}</button></DialogActions>
    </form>
  );
}

function ReportDetails({ report, token, onClose, onChanged }: {
  report: Report;
  token: string | null;
  onClose: () => void;
  onChanged: () => void;
}) {
  const { profile } = useAuth();
  const { notify } = useToast();
  const history = useQuery({
    queryKey: ["extractions", report.id],
    queryFn: () => api<{ items: ExtractionRecord[] }>("/api/v1/reports/" + report.id + "/extractions", token),
  });
  const retry = useMutation({
    mutationFn: () => api("/api/v1/reports/" + report.id + "/retry", token, { method: "POST" }),
    onSuccess: () => { notify("Report re-queued for extraction.", "success"); onChanged(); onClose(); },
    onError: (error) => notify(errorText(error), "error"),
  });

  return (
    <>
      <div className="dialog-body">
        <section><h3>Original report</h3><p className="item-quote">{report.description}</p><p className="item-meta">Location: {report.location ?? "None"}</p><p className="item-meta">Status: <strong>{report.status}</strong> · Urgency: <strong>{report.urgency}</strong></p></section>
        <h3>Extraction history ({history.data?.items.length ?? 0})</h3>
        {history.isPending ? <p className="empty-state">Loading extraction provenance…</p> : history.error ? <p className="status-error">{errorText(history.error)}</p> : !history.data?.items.length ? <p className="item-meta">No extraction records yet.</p> : history.data.items.map((record) => (
          <article className="item-card extraction-record" key={record.version}>
            <div className="item-header"><strong>v{record.version} · {record.provider}</strong><span className={"badge " + (record.validation_state === "VALIDATED" ? "badge-ready" : "badge-quarantined")}>{record.validation_state}</span></div>
            <p className="item-meta">Model: {record.model || "deterministic"} · {record.duration_ms}ms · Schema: v{record.schema_version}</p>
            <p><strong>Summary:</strong> {record.result.incident_summary}</p>
            {record.result.source_evidence?.length ? <p className="item-meta">Evidence: “{record.result.source_evidence.join("”, “")}”</p> : null}
          </article>
        ))}
      </div>
      <div className="dialog-actions">
        <button className="button button-outline" type="button" onClick={onClose}>Close</button>
        {profile?.role === "coordinator" && <button className="button button-action" type="button" disabled={retry.isPending} onClick={() => retry.mutate()}>{retry.isPending ? "Re-queueing…" : "Re-queue Extraction"}</button>}
      </div>
    </>
  );
}

function DialogActions({ onClose, children }: { onClose: () => void; children: ReactNode }) {
  return <div className="dialog-actions"><button className="button button-outline" type="button" onClick={onClose}>Cancel</button>{children}</div>;
}

function dialogTitle(dialog: WorkspaceDialog): string {
  if (dialog.type === "incident") return "Create Emergency Incident";
  if (dialog.type === "task") return "Propose Response Task";
  if (dialog.type === "assign") return "Assign Task to Responder / Team";
  return "Report & Extraction Provenance";
}
