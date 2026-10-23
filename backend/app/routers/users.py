"""Authentication identity, user roster, and role management routes."""

import os
import secrets
import uuid

from fastapi import APIRouter, Header, HTTPException

from app import auth, db
from app.auth import Coordinator
from app.schemas import UserRoleUpdate
from app.services import write_audit

router = APIRouter(prefix="/api/v1", tags=["auth"])


@router.get("/auth/me")
def auth_me(authorization: str | None = Header(default=None)):
    """Return the authenticated user's server-assigned role, including pending users."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Supabase sign-in required")
    token = authorization.removeprefix("Bearer ").strip()
    if os.getenv("SANKET_DEMO_TOKENS", "").casefold() == "true":
        for role, env_name in (("coordinator", "COORDINATOR_TOKEN"), ("responder", "RESPONDER_TOKEN")):
            expected = os.getenv(env_name, "")
            if expected and secrets.compare_digest(token, expected):
                return {"id": f"demo-{role}", "email": f"demo-{role}@sanket.ai", "role": role}
    user = auth.supabase_user_for_token(token)
    role = auth.profile_role(user)
    return {"id": user["id"], "email": user["email"], "role": role}


@router.get("/users")
def list_users(actor: Coordinator):
    """List registered users and their server-assigned access roles."""
    with db.session() as conn:
        rows = conn.execute("SELECT user_id,email,role,created_at FROM user_roles ORDER BY created_at").fetchall()
    return {"items": [dict(row) for row in rows]}


@router.patch("/users/{user_id}/role")
def update_user_role(user_id: str, payload: UserRoleUpdate, actor: Coordinator):
    """Approve, change, or suspend an account's application role."""
    try:
        normalized_id = str(uuid.UUID(user_id))
    except ValueError as exc:
        raise HTTPException(status_code=422, detail="User id must be a UUID") from exc
    with db.session() as conn:
        user = conn.execute("SELECT email FROM user_roles WHERE user_id=?", (normalized_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User profile not found")
        if actor[1].casefold() == user["email"].casefold() and payload.role != "coordinator":
            raise HTTPException(status_code=409, detail="Coordinators cannot remove their own coordinator access")
        conn.execute("UPDATE user_roles SET role=? WHERE user_id=?", (payload.role, normalized_id))
        write_audit(conn, actor[1], "USER_ROLE_UPDATED", "user", normalized_id, f"role={payload.role}")
    return {"user_id": normalized_id, "email": user["email"], "role": payload.role}
