import { useState } from "react";
import type { Incident, UserRole } from "../../types";

/** Render searchable incidents and coordinator task-proposal actions. */
export function IncidentsPanel({ incidents, role, onRefresh, onCreate, onPropose }: {
  incidents: Incident[];
  role: UserRole;
  onRefresh: () => void;
  onCreate: () => void;
  onPropose: (incident: Incident) => void;
}) {
  const [search, setSearch] = useState("");
  const visible = incidents.filter((incident) =>
    (incident.title + " " + incident.summary + " " + (incident.location ?? "")).toLowerCase().includes(search.toLowerCase()));

  return (
    <>
      <div className="panel-toolbar">
        <div className="filter-group"><label className="visually-hidden" htmlFor="incidents-search">Search incidents</label><input id="incidents-search" type="search" className="search-input-sm" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search incidents by title, summary, location..." /></div>
        <div className="toolbar-actions">
          <button className="button button-quiet button-sm" type="button" onClick={onRefresh}>↻ Refresh</button>
          {role === "coordinator" && <button className="button button-primary button-sm" type="button" onClick={onCreate}>+ New Incident</button>}
        </div>
      </div>
      <div className="items-list" aria-live="polite">
        {visible.length === 0 ? <div className="empty-state">No incidents found.</div> : visible.map((incident) => (
          <article className="item-card" key={incident.id}>
            <div className="item-header"><h3 className="item-title">{incident.title}</h3><div className="item-badges"><span className="badge badge-ready">{incident.status}</span><span className="badge badge-role">{incident.report_count} Linked Report(s)</span></div></div>
            <div className="item-body"><p>{incident.summary}</p>{incident.location && <p className="item-meta">📍 {incident.location}</p>}<span className="item-meta">Created: {new Date(incident.created_at).toLocaleString()}</span></div>
            {role === "coordinator" && <div className="item-actions"><button className="button button-primary button-sm" type="button" onClick={() => onPropose(incident)}>+ Propose Task</button></div>}
          </article>
        ))}
      </div>
    </>
  );
}
