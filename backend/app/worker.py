"""Durable local worker for deterministic extraction jobs."""

import argparse
import os
import time
import uuid
from datetime import datetime, timedelta, timezone

from app import db
from app.gemini_service import ExtractionQuarantined, extract_with_gemini
from app.services import extract_report, to_json, utc_now


def process_one() -> dict[str, object]:
    """Atomically claim one available job and store its extraction proposal."""
    db.initialize()
    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()
    with db.session() as conn:
        if db.using_postgres():
            expired = conn.execute(
                "SELECT id,report_id,attempts FROM jobs WHERE status='PROCESSING' AND lease_until<? FOR UPDATE SKIP LOCKED",
                (now_iso,),
            ).fetchall()
        else:
            conn.execute("BEGIN IMMEDIATE")
            expired = conn.execute("SELECT id,report_id,attempts FROM jobs WHERE status='PROCESSING' AND lease_until<?", (now_iso,)).fetchall()
        for stale in expired:
            if stale["attempts"] >= 3:
                conn.execute("UPDATE jobs SET status='FAILED',lease_until=NULL,last_error='worker lease expired' WHERE id=?", (stale["id"],))
                conn.execute("UPDATE reports SET status='READY_FOR_REVIEW' WHERE id=?", (stale["report_id"],))
            else:
                conn.execute("UPDATE jobs SET status='QUEUED',lease_until=NULL,last_error='worker lease expired' WHERE id=?", (stale["id"],))
        claim_query = "SELECT * FROM jobs WHERE status='QUEUED' AND available_at<=? AND attempts<3 ORDER BY id LIMIT 1"
        if db.using_postgres():
            claim_query += " FOR UPDATE SKIP LOCKED"
        job = conn.execute(claim_query, (now_iso,)).fetchone()
        if not job:
            return {"processed": False}
        lease = (now + timedelta(minutes=2)).isoformat()
        claimed = conn.execute("UPDATE jobs SET status='PROCESSING',attempts=attempts+1,lease_until=? WHERE id=? AND status='QUEUED'",
                               (lease, job["id"]))
        if claimed.rowcount != 1:
            return {"processed": False}
        report = conn.execute("SELECT * FROM reports WHERE id=?", (job["report_id"],)).fetchone()
    provider_configured = bool(os.getenv("GEMINI_API_KEY", "").strip()) and bool(report["ai_consent"])
    quarantine = False
    try:
        if provider_configured:
            try:
                extraction, metadata = extract_with_gemini(report["description"], report["location"])
                extraction = extraction.model_copy(update={
                    "ambiguity_notes": [*extraction.ambiguity_notes, "AI-generated proposal; coordinator verification required."]
                })
            except ExtractionQuarantined:
                quarantine = True
                extraction = extract_report(report["description"], report["location"])
                metadata = {"provider": "google-gemini", "model": os.getenv("GEMINI_MODEL", "gemini-3.8-flash"),
                            "validation_state": "QUARANTINED", "error_category": "schema_validation"}
            except Exception as provider_error:
                extraction = extract_report(report["description"], report["location"])
                metadata = {"provider": "google-gemini", "model": os.getenv("GEMINI_MODEL", "gemini-3.8-flash"),
                            "validation_state": "FALLBACK", "error_category": type(provider_error).__name__}
        else:
            extraction = extract_report(report["description"], report["location"])
            metadata = {"provider": "deterministic", "model": None, "validation_state": "DETERMINISTIC",
                        "schema_version": "1", "token_usage": None}
    except Exception as exc:
        with db.session() as conn:
            current = conn.execute("SELECT attempts FROM jobs WHERE id=?", (job["id"],)).fetchone()
            attempts = current["attempts"] if current else 3
            if attempts >= 3:
                conn.execute("UPDATE jobs SET status='FAILED',lease_until=NULL,last_error=? WHERE id=?", (type(exc).__name__, job["id"]))
                conn.execute("UPDATE reports SET status='READY_FOR_REVIEW' WHERE id=?", (report["id"],))
            else:
                retry_at = (datetime.now(timezone.utc) + timedelta(seconds=2 ** attempts)).isoformat()
                conn.execute("UPDATE jobs SET status='QUEUED',available_at=?,lease_until=NULL,last_error=? WHERE id=?",
                             (retry_at, type(exc).__name__, job["id"]))
        return {"processed": False, "retry_scheduled": attempts < 3}
    with db.session() as conn:
        result_json = to_json(extraction.model_dump(mode="json"))
        metadata.setdefault("duration_ms", 0)
        metadata.setdefault("schema_version", "1")
        status = "QUARANTINED" if quarantine else "READY_FOR_REVIEW"
        conn.execute("UPDATE reports SET extraction_json=?,processing_metadata_json=?,urgency=?,status=? WHERE id=?",
                     (result_json, to_json(metadata), extraction.urgency_level.value, status, report["id"]))
        version = conn.execute("SELECT COALESCE(MAX(version),0)+1 AS version FROM extraction_records WHERE report_id=?", (report["id"],)).fetchone()["version"]
        conn.execute(
            "INSERT INTO extraction_records(id,report_id,version,provider,model,prompt_hash,schema_version,validation_state,duration_ms,token_usage_json,result_json,created_at) "
            "VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",
            (str(uuid.uuid4()), report["id"], version, metadata.get("provider", "deterministic"),
             metadata.get("model"), metadata.get("prompt_hash"), metadata["schema_version"],
             metadata.get("validation_state", "DETERMINISTIC"), int(metadata.get("duration_ms", 0)),
             to_json(metadata["token_usage"]) if metadata.get("token_usage") is not None else None,
             result_json, utc_now()),
        )
        final_job = "FAILED" if quarantine else "SUCCEEDED"
        conn.execute("UPDATE jobs SET status=?,lease_until=NULL,last_error=? WHERE id=?",
                     (final_job, "schema_validation" if quarantine else None, job["id"]))
    return {"processed": True, "report_id": report["id"], "validation": metadata["validation_state"],
            "ai_provider_called": provider_configured}


def main() -> None:
    """Poll the durable queue until interrupted."""
    parser = argparse.ArgumentParser(description="SANKET local report worker")
    parser.add_argument("--poll-seconds", type=float, default=2.0)
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()
    while True:
        result = process_one()
        if args.once:
            print(result)
            return
        if not result.get("processed"):
            time.sleep(max(0.1, args.poll_seconds))


if __name__ == "__main__":
    main()
