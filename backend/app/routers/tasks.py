from typing import Any

from fastapi import APIRouter, HTTPException

from app import db
from app.auth import Actor
from app.schemas import TaskTransition
from app.services import valid_task_transition, write_audit

router = APIRouter(prefix="/api/v1/tasks", tags=["tasks"])


@router.get("")
def list_tasks(actor: Actor) -> dict[str, list[dict[str, Any]]]:
    """List response tasks with associated incident titles."""
    with db.session() as conn:
        rows = conn.execute(
            "SELECT t.*,i.title AS incident_title FROM tasks t JOIN incidents i ON i.id=t.incident_id ORDER BY t.created_at DESC"
        ).fetchall()
    return {"items": [dict(r) for r in rows]}


@router.get("/{task_id}")
def get_task(task_id: str, actor: Actor) -> dict[str, Any]:
    """Return single task with incident title."""
    with db.session() as conn:
        row = conn.execute(
            "SELECT t.*,i.title AS incident_title FROM tasks t JOIN incidents i ON i.id=t.incident_id WHERE t.id=?",
            (task_id,),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Task not found")
    return dict(row)


@router.patch("/{task_id}")
def transition_task(task_id: str, payload: TaskTransition, actor: Actor) -> dict[str, Any]:
    """Apply a permitted task transition with optimistic version checking."""
    with db.session() as conn:
        row = conn.execute("SELECT * FROM tasks WHERE id=?", (task_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Task not found")
        if payload.version != row["version"]:
            raise HTTPException(status_code=409, detail="Task changed; reload and retry")
        if actor[0] != "coordinator" and payload.status not in ("IN_PROGRESS", "COMPLETED"):
            raise HTTPException(status_code=403, detail="Responder may only progress approved work")
        if not valid_task_transition(row["status"], payload.status):
            raise HTTPException(status_code=409, detail=f"Invalid task transition {row['status']} → {payload.status}")
        if payload.status == "ASSIGNED" and not payload.assignee:
            raise HTTPException(status_code=422, detail="An assignee is required before assignment")
        next_version = row["version"] + 1
        updated = conn.execute(
            "UPDATE tasks SET status=?,assignee=COALESCE(?,assignee),notes=COALESCE(?,notes),version=? WHERE id=? AND version=?",
            (payload.status, payload.assignee, payload.notes, next_version, task_id, payload.version),
        )
        if updated.rowcount != 1:
            raise HTTPException(status_code=409, detail="Task changed; reload and retry")
        write_audit(conn, actor[1], f"TASK_{payload.status}", "task", task_id, detail=payload.notes or "")
    return {
        "id": task_id,
        "status": payload.status,
        "assignee": payload.assignee or row["assignee"],
        "notes": payload.notes or row["notes"],
        "version": next_version,
    }
