import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { api, errorText } from "../../api";
import { useAuth } from "../../auth/AuthProvider";
import { useToast } from "../ToastProvider";
import type { ResponseTask, UserRole } from "../../types";

/** Filter and display tasks with server-validated state transitions. */
export function TasksPanel({ tasks, role, onRefresh, onAssign }: { tasks: ResponseTask[]; role: UserRole; onRefresh: () => void; onAssign: (task: ResponseTask) => void }) {
  const [filter, setFilter] = useState("");
  const { session } = useAuth();
  const { notify } = useToast();
  const move = useMutation({
    mutationFn: ({ task, status }: { task: ResponseTask; status: string }) =>
      api("/api/v1/tasks/" + task.id, session?.access_token, {
        method: "PATCH",
        body: JSON.stringify({ status, assignee: null, version: task.version }),
      }),
    onSuccess: (_, variables) => {
      notify("Task transitioned to " + variables.status + ".", "success");
      onRefresh();
    },
    onError: (error) => notify(errorText(error), "error"),
  });
  const visible = tasks.filter((task) => !filter || task.status === filter);

  return (
    <>
      <div className="panel-toolbar">
        <div className="filter-group"><label className="visually-hidden" htmlFor="tasks-filter">Filter tasks</label><select id="tasks-filter" className="select-sm" value={filter} onChange={(event) => setFilter(event.target.value)}><option value="">All Task States</option><option value="PROPOSED">Proposed</option><option value="APPROVED">Approved</option><option value="ASSIGNED">Assigned</option><option value="IN_PROGRESS">In Progress</option><option value="COMPLETED">Completed</option><option value="CANCELLED">Cancelled</option></select></div>
        <div className="toolbar-actions"><button className="button button-quiet button-sm" type="button" onClick={onRefresh}>↻ Refresh</button></div>
      </div>
      <div className="items-list" aria-live="polite">
        {visible.length === 0 ? <div className="empty-state">No response tasks found.</div> : visible.map((task) => (
          <article className="item-card" key={task.id}>
            <div className="item-header"><h3 className="item-title">{task.title}</h3><div className="item-badges"><span className="badge badge-ready">{task.status}</span><span className="badge badge-role">v{task.version}</span></div></div>
            <div className="item-body"><p>{task.description}</p><p className="item-meta">Incident: <strong>{task.incident_title}</strong></p>{task.assignee ? <p className="item-meta">👤 Assigned: <strong>{task.assignee}</strong></p> : <p className="item-meta"><em>Unassigned</em></p>}</div>
            <div className="item-actions">
              {role === "coordinator" && task.status === "PROPOSED" && <><button className="button button-primary button-sm" type="button" disabled={move.isPending} onClick={() => move.mutate({ task, status: "APPROVED" })}>Approve Task</button><button className="button button-quiet button-sm" type="button" disabled={move.isPending} onClick={() => move.mutate({ task, status: "REJECTED" })}>Reject</button></>}
              {role === "coordinator" && task.status === "APPROVED" && <button className="button button-primary button-sm" type="button" onClick={() => onAssign(task)}>Assign Task</button>}
              {(role === "responder" || role === "coordinator") && task.status === "ASSIGNED" && <button className="button button-primary button-sm" type="button" disabled={move.isPending} onClick={() => move.mutate({ task, status: "IN_PROGRESS" })}>Start Work</button>}
              {(role === "responder" || role === "coordinator") && task.status === "IN_PROGRESS" && <button className="button button-primary button-sm" type="button" disabled={move.isPending} onClick={() => move.mutate({ task, status: "COMPLETED" })}>Mark Completed</button>}
            </div>
          </article>
        ))}
      </div>
    </>
  );
}
