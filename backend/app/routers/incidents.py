"""Operational incident lifecycle, report association, and task proposal routes."""

import uuid

from fastapi import APIRouter, HTTPException

from app import db
from app.auth import Actor, Coordinator
from app.schemas import IncidentCreate, IncidentUpdate, ReportAssociation, TaskCreate
from app.services import rank_incident_candidates, utc_now, write_audit

router = APIRouter(prefix="/api/v1/incidents", tags=["incidents"])


@router.get("")
def list_incidents(actor: Actor):
    """List operational incidents and report-association counts."""
    with db.session() as conn:
        rows = conn.execute(
            "SELECT i.*,COUNT(a.report_id) AS report_count FROM incidents i "
            "LEFT JOIN associations a ON a.incident_id=i.id AND a.state='CONFIRMED' "
            "GROUP BY i.id ORDER BY i.created_at DESC"
        ).fetchall()
    return {"items": [dict(r) for r in rows]}


@router.get("/{incident_id}")
def get_incident(incident_id: str, actor: Actor):
    """Return single incident with associated reports and tasks."""
    with db.session() as conn:
        incident = conn.execute("SELECT * FROM incidents WHERE id=?", (incident_id,)).fetchone()
        if not incident:
            raise HTTPException(status_code=404, detail="Incident not found")
        reports = conn.execute(
            "SELECT r.id,r.description,r.location,r.status,r.urgency,r.received_at,a.state,a.created_at AS associated_at "
            "FROM associations a JOIN reports r ON r.id=a.report_id WHERE a.incident_id=?", (incident_id,)
        ).fetchall()
        tasks = conn.execute("SELECT * FROM tasks WHERE incident_id=? ORDER BY created_at DESC", (incident_id,)).fetchall()
    data = dict(incident)
    data["reports"] = [dict(r) for r in reports]
    data["tasks"] = [dict(t) for t in tasks]
    return data


@router.post("", status_code=201)
def create_incident(payload: IncidentCreate, actor: Coordinator):
    """Create an incident and optionally associate its source report atomically."""
    incident_id, now = str(uuid.uuid4()), utc_now()
    try:
        with db.session() as conn:
            if payload.report_id and not conn.execute("SELECT 1 FROM reports WHERE id=?", (payload.report_id,)).fetchone():
                raise HTTPException(status_code=404, detail="Source report not found")
            if payload.report_id and not conn.execute("SELECT 1 FROM reports WHERE id=? AND reviewed=TRUE", (payload.report_id,)).fetchone():
                raise HTTPException(status_code=409, detail="Review the source report before creating its incident")
            conn.execute(
                "INSERT INTO incidents(id,title,summary,location,created_at) VALUES(?,?,?,?,?)",
                (incident_id, payload.title, payload.summary, payload.location, now),
            )
            if payload.report_id:
                conn.execute("INSERT INTO associations(report_id,incident_id,state,created_at) VALUES(?,?,?,?)",
                             (payload.report_id, incident_id, "CONFIRMED", now))
            write_audit(conn, actor[1], "INCIDENT_CREATED", "incident", incident_id)
    except HTTPException:
        raise
    return {"id": incident_id, "title": payload.title, "status": "OPEN", "created_at": now}


@router.patch("/{incident_id}")
def update_incident(incident_id: str, payload: IncidentUpdate, actor: Coordinator):
    """Update operational incident status or attributes."""
    with db.session() as conn:
        row = conn.execute("SELECT * FROM incidents WHERE id=?", (incident_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Incident not found")
        updates = []
        params = []
        if payload.title is not None:
            updates.append("title=?")
            params.append(payload.title)
        if payload.summary is not None:
            updates.append("summary=?")
            params.append(payload.summary)
        if payload.location is not None:
            updates.append("location=?")
            params.append(payload.location)
        if payload.status is not None:
            updates.append("status=?")
            params.append(payload.status)
        if updates:
            params.append(incident_id)
            conn.execute(f"UPDATE incidents SET {', '.join(updates)} WHERE id=?", params)
            write_audit(conn, actor[1], f"INCIDENT_{payload.status or 'UPDATED'}", "incident", incident_id)
        updated = conn.execute("SELECT * FROM incidents WHERE id=?", (incident_id,)).fetchone()
    return dict(updated)


@router.post("/{incident_id}/review")
def review_incident(incident_id: str, actor: Coordinator):
    """Confirm human coordinator verification of an operational incident."""
    with db.session() as conn:
        row = conn.execute("SELECT * FROM incidents WHERE id=?", (incident_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Incident not found")
        write_audit(conn, actor[1], "INCIDENT_REVIEWED", "incident", incident_id)
    return {"incident_id": incident_id, "reviewed": True}


@router.get("/{incident_id}/matches")
def incident_matches(incident_id: str, actor: Actor):
    """List explainable candidate reports that could be associated with this incident."""
    with db.session() as conn:
        incident = conn.execute("SELECT id,title,summary,location,status FROM incidents WHERE id=?", (incident_id,)).fetchone()
        if not incident:
            raise HTTPException(status_code=404, detail="Incident not found")
        unassociated_reports = conn.execute(
            "SELECT id,description,location,received_at,status FROM reports "
            "WHERE id NOT IN (SELECT report_id FROM associations WHERE incident_id=?)",
            (incident_id,),
        ).fetchall()
    ranked = []
    for rep in unassociated_reports:
        cands = rank_incident_candidates(dict(rep), [dict(incident)])
        if cands and cands[0]["similarity"] > 0:
            ranked.append({
                "report_id": rep["id"],
                "description": rep["description"],
                "location": rep["location"],
                "received_at": rep["received_at"],
                "similarity": cands[0]["similarity"],
                "evidence": cands[0]["evidence"],
            })
    ranked.sort(key=lambda x: x["similarity"], reverse=True)
    return {"items": ranked[:15], "method": "shared terms and exact location match"}


@router.post("/{incident_id}/associations")
def decide_association(incident_id: str, payload: ReportAssociation, actor: Coordinator):
    """Confirm or reject a reviewed report-to-incident relationship."""
    now = utc_now()
    with db.session() as conn:
        if not conn.execute("SELECT 1 FROM incidents WHERE id=?", (incident_id,)).fetchone():
            raise HTTPException(status_code=404, detail="Incident not found")
        report = conn.execute("SELECT reviewed FROM reports WHERE id=?", (payload.report_id,)).fetchone()
        if not report:
            raise HTTPException(status_code=404, detail="Report not found")
        if not report["reviewed"]:
            raise HTTPException(status_code=409, detail="Review the source report before deciding its association")
        conn.execute(
            "INSERT INTO associations(report_id,incident_id,state,created_at) VALUES(?,?,?,?) "
            "ON CONFLICT(report_id,incident_id) DO UPDATE SET state=excluded.state,created_at=excluded.created_at",
            (payload.report_id, incident_id, payload.state, now),
        )
        write_audit(conn, actor[1], f"REPORT_ASSOCIATION_{payload.state}", "report", payload.report_id,
                    f"incident_id={incident_id}")
    return {"report_id": payload.report_id, "incident_id": incident_id, "state": payload.state}


@router.post("/{incident_id}/tasks", status_code=201)
def create_task(incident_id: str, payload: TaskCreate, actor: Coordinator):
    """Propose a response task for an existing incident."""
    task_id, now = str(uuid.uuid4()), utc_now()
    with db.session() as conn:
        if not conn.execute("SELECT 1 FROM incidents WHERE id=?", (incident_id,)).fetchone():
            raise HTTPException(status_code=404, detail="Incident not found")
        conn.execute("INSERT INTO tasks(id,incident_id,title,description,created_at) VALUES(?,?,?,?,?)",
                     (task_id, incident_id, payload.title, payload.description, now))
        write_audit(conn, actor[1], "TASK_PROPOSED", "task", task_id)
    return {"id": task_id, "incident_id": incident_id, "status": "PROPOSED", "version": 1}
