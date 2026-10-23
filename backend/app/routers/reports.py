"""Emergency report intake, receipts, extractions, and candidate matching routes."""

import json
import uuid

from fastapi import APIRouter, Header, HTTPException, Query

from app import db
from app.auth import Actor, Coordinator
from app.schemas import ReportSubmission
from app.services import rank_incident_candidates, utc_now, write_audit

router = APIRouter(prefix="/api/v1/reports", tags=["reports"])


@router.post("", status_code=201)
def submit_report(payload: ReportSubmission, idempotency_key: str | None = Header(default=None, alias="Idempotency-Key")):
    """Persist a public report and its durable processing job atomically."""
    now = utc_now()
    report_id = str(uuid.uuid4())
    if idempotency_key and len(idempotency_key) > 128:
        raise HTTPException(status_code=400, detail="Idempotency-Key is too long")
    try:
        with db.session() as conn:
            if idempotency_key:
                found = conn.execute("SELECT report_id FROM idempotency_keys WHERE key=?", (idempotency_key,)).fetchone()
                if found:
                    return {"receipt_id": found["report_id"], "status": "QUEUED"}
            conn.execute(
                "INSERT INTO reports(id,description,location,received_at,ai_consent) VALUES(?,?,?,?,?)",
                (report_id, payload.description, payload.location, now, payload.ai_consent),
            )
            conn.execute("INSERT INTO jobs(report_id,available_at) VALUES(?,?)", (report_id, now))
            if idempotency_key:
                conn.execute("INSERT INTO idempotency_keys(key,report_id) VALUES(?,?)", (idempotency_key, report_id))
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Report could not be persisted; retry submission") from exc
    return {"receipt_id": report_id, "status": "QUEUED"}


@router.get("/{report_id}/receipt")
def receipt(report_id: str):
    """Return non-sensitive processing acknowledgement for a report receipt."""
    with db.session() as conn:
        row = conn.execute("SELECT id,status,received_at FROM reports WHERE id=?", (report_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Report not found")
    return dict(row)


@router.get("")
def list_reports(actor: Actor, status: str | None = None, limit: int = Query(50, ge=1, le=100), offset: int = Query(0, ge=0)):
    """List reports with bounded pagination for authenticated operators."""
    query = (
        "SELECT id,description,location,received_at,status,urgency,reviewed,extraction_json,processing_metadata_json,"
        "(SELECT COUNT(*) FROM associations WHERE report_id=reports.id AND state='CONFIRMED') AS association_count FROM reports"
    )
    params: list[object] = []
    if status:
        query += " WHERE status=?"
        params.append(status.upper())
    query += " ORDER BY received_at DESC LIMIT ? OFFSET ?"
    params.extend((limit, offset))
    with db.session() as conn:
        rows = [dict(r) for r in conn.execute(query, params).fetchall()]
    for row in rows:
        row["extraction"] = json.loads(row.pop("extraction_json")) if row["extraction_json"] else None
        row["processing_metadata"] = json.loads(row.pop("processing_metadata_json")) if row["processing_metadata_json"] else None
    return {"items": rows, "limit": limit, "offset": offset}


@router.get("/{report_id}")
def get_report(report_id: str, actor: Actor):
    """Return single report details with extraction proposals."""
    query = (
        "SELECT id,description,location,received_at,status,urgency,reviewed,extraction_json,processing_metadata_json,"
        "(SELECT COUNT(*) FROM associations WHERE report_id=reports.id AND state='CONFIRMED') AS association_count "
        "FROM reports WHERE id=?"
    )
    with db.session() as conn:
        row = conn.execute(query, (report_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Report not found")
    data = dict(row)
    data["extraction"] = json.loads(data.pop("extraction_json")) if data["extraction_json"] else None
    data["processing_metadata"] = json.loads(data.pop("processing_metadata_json")) if data["processing_metadata_json"] else None
    return data


@router.post("/{report_id}/retry")
def retry_report(report_id: str, actor: Coordinator):
    """Requeue a report processing job for retry."""
    with db.session() as conn:
        report = conn.execute("SELECT id FROM reports WHERE id=?", (report_id,)).fetchone()
        if not report:
            raise HTTPException(status_code=404, detail="Report not found")
        now = utc_now()
        conn.execute("UPDATE reports SET status='QUEUED' WHERE id=?", (report_id,))
        conn.execute(
            "INSERT INTO jobs(report_id,status,available_at,attempts,lease_until,last_error) VALUES(?,?,?,0,NULL,NULL) "
            "ON CONFLICT(report_id) DO UPDATE SET status='QUEUED',available_at=excluded.available_at,attempts=0,lease_until=NULL,last_error=NULL",
            (report_id, "QUEUED", now),
        )
        write_audit(conn, actor[1], "REPORT_RETRY_QUEUED", "report", report_id)
    return {"report_id": report_id, "status": "QUEUED"}


@router.get("/{report_id}/extractions")
def list_extractions(report_id: str, actor: Actor):
    """Return versioned extraction proposals and provider validation metadata."""
    with db.session() as conn:
        if not conn.execute("SELECT 1 FROM reports WHERE id=?", (report_id,)).fetchone():
            raise HTTPException(status_code=404, detail="Report not found")
        rows = conn.execute(
            "SELECT version,provider,model,prompt_hash,schema_version,validation_state,duration_ms,token_usage_json,result_json,created_at "
            "FROM extraction_records WHERE report_id=? ORDER BY version DESC", (report_id,)
        ).fetchall()
    items = []
    for row in rows:
        item = dict(row)
        item["token_usage"] = json.loads(item.pop("token_usage_json")) if item["token_usage_json"] else None
        item["result"] = json.loads(item.pop("result_json"))
        items.append(item)
    return {"items": items}


@router.post("/{report_id}/review")
def review_report(report_id: str, actor: Coordinator):
    """Mark a report reviewed while retaining its original submitted text."""
    with db.session() as conn:
        result = conn.execute("UPDATE reports SET reviewed=TRUE WHERE id=?", (report_id,))
        if result.rowcount != 1:
            raise HTTPException(status_code=404, detail="Report not found")
        write_audit(conn, actor[1], "REPORT_REVIEWED", "report", report_id)
    return {"report_id": report_id, "reviewed": True}


@router.get("/{report_id}/matches")
def report_matches(report_id: str, actor: Actor):
    """List explainable incident candidates for coordinator review."""
    with db.session() as conn:
        report = conn.execute("SELECT id,description,location FROM reports WHERE id=?", (report_id,)).fetchone()
        if not report:
            raise HTTPException(status_code=404, detail="Report not found")
        incidents = conn.execute(
            "SELECT id,title,summary,status,location FROM incidents "
            "WHERE id NOT IN (SELECT incident_id FROM associations WHERE report_id=?)",
            (report_id,),
        ).fetchall()
    return {"items": rank_incident_candidates(dict(report), [dict(item) for item in incidents]),
            "method": "shared terms and exact submitted-location wording; heuristic only"}
