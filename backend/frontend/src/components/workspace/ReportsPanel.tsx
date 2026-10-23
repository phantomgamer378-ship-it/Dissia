import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { api, errorText } from "../../api";
import { useToast } from "../ToastProvider";
import type { IncidentCandidate, Report, UserRole } from "../../types";

interface ReportsPanelProps {
  reports: Report[];
  token: string | null;
  role: UserRole;
  onChanged: () => void;
  onCreateIncident: (report: Report) => void;
  onInspect: (report: Report) => void;
}

/** Filter and render source reports with review, matching, and provenance actions. */
export function ReportsPanel({ reports, token, role, onChanged, onCreateIncident, onInspect }: ReportsPanelProps) {
  const [filter, setFilter] = useState("");
  const [search, setSearch] = useState("");
  const { notify } = useToast();
  const review = useMutation({
    mutationFn: (id: string) => api("/api/v1/reports/" + id + "/review", token, { method: "POST" }),
    onSuccess: () => { notify("Report marked reviewed.", "success"); onChanged(); },
    onError: (error) => notify(errorText(error), "error"),
  });
  const visible = reports.filter((report) => {
    const matchesStatus = !filter || report.status === filter;
    const text = (report.description + " " + (report.location ?? "") + " " + report.id).toLowerCase();
    return matchesStatus && (!search || text.includes(search.toLowerCase()));
  });

  return (
    <>
      <div className="panel-toolbar">
        <div className="filter-group">
          <label className="visually-hidden" htmlFor="reports-filter">Filter reports by status</label>
          <select id="reports-filter" className="select-sm" value={filter} onChange={(event) => setFilter(event.target.value)}>
            <option value="">All Statuses</option><option value="QUEUED">Queued</option><option value="READY_FOR_REVIEW">Ready for Review</option><option value="QUARANTINED">Quarantined</option>
          </select>
          <label className="visually-hidden" htmlFor="reports-search">Search reports</label>
          <input id="reports-search" type="search" className="search-input-sm" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search report text, location, or ID..." />
        </div>
        <div className="toolbar-actions"><button className="button button-quiet button-sm" type="button" onClick={onChanged}>↻ Refresh</button></div>
      </div>
      <div className="items-list" aria-live="polite">
        {visible.length === 0 ? <div className="empty-state">No matching reports found.</div> : visible.map((report) => (
          <article className="item-card" key={report.id}>
            <div className="item-header">
              <div className="item-title-group"><h3 className="item-title">Report · <code>{report.id.slice(0, 8)}</code></h3><span className="item-meta">{new Date(report.received_at).toLocaleString()}</span></div>
              <div className="item-badges"><span className={"badge " + reportStatusClass(report.status)}>{report.status}</span><span className={"badge badge-urgency-" + (report.urgency || "unknown").toLowerCase()}>{report.urgency}</span><span className={"badge " + (report.reviewed ? "badge-ready" : "badge-queued")}>{report.reviewed ? "✓ Reviewed" : "Needs Review"}</span></div>
            </div>
            <div className="item-body">
              <p className="item-quote">{report.description}</p>
              {report.location && <p className="item-meta">📍 {report.location}</p>}
              {report.extraction && <div className="extraction-summary-chip"><strong>Proposal [{report.extraction.incident_category}]:</strong> {report.extraction.incident_summary}</div>}
            </div>
            <div className="item-actions">
              {!report.reviewed && role === "coordinator" && <button className="button button-primary button-sm" type="button" disabled={review.isPending} onClick={() => review.mutate(report.id)}>Mark Reviewed</button>}
              {role === "coordinator" && <CandidateToggle report={report} token={token} onChanged={onChanged} />}
              {role === "coordinator" && report.reviewed && report.association_count === 0 && <button className="button button-primary button-sm" type="button" onClick={() => onCreateIncident(report)}>Create Incident</button>}
              <button className="button button-quiet button-sm" type="button" onClick={() => onInspect(report)}>Inspect Provenance</button>
            </div>
          </article>
        ))}
      </div>
    </>
  );
}

function CandidateToggle({ report, token, onChanged }: { report: Report; token: string | null; onChanged: () => void }) {
  const [expanded, setExpanded] = useState(false);
  const { notify } = useToast();
  const query = useQuery({
    queryKey: ["report-matches", report.id],
    enabled: expanded,
    queryFn: () => api<{ items: IncidentCandidate[]; method: string }>("/api/v1/reports/" + report.id + "/matches", token),
  });
  const decide = useMutation({
    mutationFn: ({ incidentId, state }: { incidentId: string; state: "CONFIRMED" | "REJECTED" }) =>
      api("/api/v1/incidents/" + incidentId + "/associations", token, {
        method: "POST",
        body: JSON.stringify({ report_id: report.id, state }),
      }),
    onSuccess: (_, variables) => {
      notify(variables.state === "CONFIRMED" ? "Report linked to incident." : "Match rejected.", "success");
      onChanged();
    },
    onError: (error) => notify(errorText(error), "error"),
  });

  return (
    <div className="candidate-control">
      <button className="button button-outline button-sm" type="button" aria-expanded={expanded} onClick={() => setExpanded((value) => !value)}>
        {expanded ? "Hide Incident Matches" : "Find Related Incidents"}
      </button>
      {expanded && (
        <div className="candidates-accordion">
          {query.isPending ? <p className="item-meta">Searching incident candidates…</p> : query.error ? <p className="status-error">{errorText(query.error)}</p> : (
            <>
              <h4>Heuristic Incident Candidates ({query.data?.items.length ?? 0})</h4>
              <p className="item-meta">{query.data?.method}</p>
              {!query.data?.items.length ? <p className="item-meta">{report.association_count ? "Report linked already." : "No candidates found."}</p> :
                query.data.items.map((candidate) => (
                  <div className="candidate-item" key={candidate.id}>
                    <div className="item-header"><strong>{candidate.title}</strong><span className="candidate-score">{(candidate.similarity * 100).toFixed(0)}%</span></div>
                    <p className="item-meta">{candidate.evidence.join(" · ")}</p>
                    {report.reviewed && <div className="item-actions">
                      <button className="button button-primary button-sm" type="button" disabled={decide.isPending} onClick={() => decide.mutate({ incidentId: candidate.id, state: "CONFIRMED" })}>Confirm Match</button>
                      <button className="button button-quiet button-sm" type="button" disabled={decide.isPending} onClick={() => decide.mutate({ incidentId: candidate.id, state: "REJECTED" })}>Reject Match</button>
                    </div>}
                  </div>
                ))}
            </>
          )}
        </div>
      )}
    </div>
  );
}

function reportStatusClass(status: string): string {
  if (status === "QUEUED") return "badge-queued";
  if (status === "READY_FOR_REVIEW") return "badge-ready";
  return "badge-quarantined";
}
