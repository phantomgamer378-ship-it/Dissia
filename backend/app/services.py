"""Deterministic report processing and task workflow rules."""

import json
import re
from datetime import datetime, timezone

from app.schemas import Category, Extraction, Urgency


def utc_now() -> str:
    """Return an ISO-8601 UTC timestamp."""
    return datetime.now(timezone.utc).isoformat()


def write_audit(conn, actor: str, action: str, target_type: str, target_id: str, detail: str = "") -> None:
    """Record a consequential action without copying sensitive report text."""
    conn.execute(
        "INSERT INTO audit(actor,action,target_type,target_id,created_at,detail) VALUES(?,?,?,?,?,?)",
        (actor, action, target_type, target_id, utc_now(), detail[:300]),
    )


def extract_report(text: str, supplied_location: str | None) -> Extraction:
    """Create a conservative, deterministic extraction proposal from a report."""
    lower = text.lower()
    category = next(
        (kind for words, kind in [
            (("flood", "water", "inundat"), Category.FLOOD),
            (("fire", "smoke", "burn"), Category.FIRE),
            (("collapse", "collapsed", "building fell"), Category.COLLAPSE),
            (("injur", "medical", "trapped", "unconscious"), Category.MEDICAL),
            (("chemical", "gas leak", "hazmat"), Category.HAZMAT),
        ] if any(word in lower for word in words)), Category.OTHER
    )
    urgency = Urgency.CRITICAL if any(term in lower for term in ("trapped", "unconscious", "people inside")) else Urgency.UNKNOWN
    clues = [supplied_location] if supplied_location else []
    evidence = [text[:240]]
    return Extraction(
        incident_category=category,
        incident_summary=text[:240],
        reported_event_time=None,
        location_wording=supplied_location,
        location_clues=clues,
        reported_hazards=[],
        reported_needs=[],
        urgency_level=urgency,
        urgency_rationale="Keyword-based suggestion; coordinator verification required." if urgency != Urgency.UNKNOWN else "Insufficient evidence to assign urgency; treat as unknown.",
        source_evidence=evidence,
        ambiguity_notes=["Deterministic prototype extraction; no AI provider was called.", "All extracted claims require human review."],
    )


def valid_task_transition(current: str, target: str) -> bool:
    """Check an allowed response-task lifecycle transition."""
    transitions = {
        "PROPOSED": {"APPROVED", "REJECTED", "CANCELLED"},
        "APPROVED": {"ASSIGNED", "CANCELLED"},
        "ASSIGNED": {"IN_PROGRESS", "CANCELLED"},
        "IN_PROGRESS": {"COMPLETED", "CANCELLED"},
    }
    return target in transitions.get(current, set())


def to_json(value: object) -> str:
    """Serialize validated data consistently for persistence."""
    return json.dumps(value, ensure_ascii=False, sort_keys=True)


def rank_incident_candidates(report: dict, incidents: list[dict]) -> list[dict]:
    """Rank possible report matches using shared terms and exact location wording.

    The returned score is a heuristic ordering aid, never a calibrated probability.
    Candidate ranking is linear in the number of incident records examined.
    """
    stop_words = {"the", "and", "for", "near", "with", "from", "that", "this", "was", "were", "has", "have"}

    def terms(value: str | None) -> set[str]:
        return {word for word in re.findall(r"[a-z0-9]{3,}", (value or "").casefold()) if word not in stop_words}

    report_terms = terms(report["description"])
    report_location = " ".join((report.get("location") or "").casefold().split())
    candidates = []
    for incident in incidents:
        shared = report_terms & terms(f"{incident['title']} {incident['summary']}")
        incident_location = " ".join((incident.get("location") or "").casefold().split())
        same_location = bool(report_location and incident_location and report_location == incident_location)
        if not same_location and len(shared) < 2:
            continue
        union_size = len(report_terms | terms(f"{incident['title']} {incident['summary']}"))
        overlap = len(shared) / union_size if union_size else 0.0
        candidates.append({
            "id": incident["id"],
            "title": incident["title"],
            "status": incident["status"],
            "similarity": round((overlap * 0.7) + (0.3 if same_location else 0.0), 3),
            "evidence": (["Same submitted location"] if same_location else []) +
                        ([f"Shared terms: {', '.join(sorted(shared)[:4])}"] if shared else []),
            "basis": "heuristic candidate rank; coordinator decision required",
        })
    return sorted(candidates, key=lambda item: item["similarity"], reverse=True)[:10]
