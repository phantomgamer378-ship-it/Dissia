import { useQuery } from "@tanstack/react-query";
import { api, errorText } from "../../api";
import type { AuditEvent } from "../../types";

/** Render coordinator audit metadata, leaving report content out of the ledger. */
export function AuditPanel({ token }: { token: string | null }) {
  const query = useQuery({
    queryKey: ["audit-log"],
    queryFn: () => api<{ items: AuditEvent[] }>("/api/v1/audit?limit=100", token),
  });

  return (
    <>
      <div className="panel-toolbar"><p className="panel-subtitle">Chronological ledger of security-relevant coordinator and responder operations. Report text is omitted for privacy.</p><div className="toolbar-actions"><button className="button button-quiet button-sm" type="button" onClick={() => void query.refetch()}>↻ Refresh Audit</button></div></div>
      <div className="audit-table-wrapper">
        {query.error ? <p className="empty-state status-error">{errorText(query.error)}</p> : (
          <table className="audit-table" aria-label="Audit log entries">
            <thead><tr><th scope="col">Timestamp</th><th scope="col">Actor</th><th scope="col">Action</th><th scope="col">Target</th><th scope="col">Details</th></tr></thead>
            <tbody>
              {query.isPending ? <tr><td colSpan={5} className="empty-state">Loading audit events…</td></tr> : !query.data?.items.length ? <tr><td colSpan={5} className="empty-state">No audit events recorded yet.</td></tr> : query.data.items.map((event, index) => (
                <tr key={event.target_id + event.action + index}>
                  <td className="item-meta">{new Date(event.created_at).toLocaleString()}</td>
                  <td><code>{event.actor}</code></td>
                  <td><span className="badge badge-ready">{event.action}</span></td>
                  <td><code>{event.target_type}:{event.target_id.slice(0, 8)}</code></td>
                  <td className="item-meta">{event.detail ?? ""}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  );
}
