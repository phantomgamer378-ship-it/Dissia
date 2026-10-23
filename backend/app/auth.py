"""Supabase Auth token validation and server-assigned SANKET roles."""

import json
import os
import secrets
import urllib.error
import urllib.request
from typing import Annotated

from fastapi import Depends, Header, HTTPException

from app import db
from app.services import utc_now


def supabase_auth_configured() -> bool:
    """Check that the browser-safe Supabase Auth settings are present."""
    return bool(os.getenv("SUPABASE_URL", "").strip() and os.getenv("SUPABASE_PUBLISHABLE_KEY", "").strip())


def supabase_user_for_token(token: str) -> dict:
    """Validate an access token with Supabase Auth and return its user record."""
    base_url = os.getenv("SUPABASE_URL", "").strip().rstrip("/")
    publishable_key = os.getenv("SUPABASE_PUBLISHABLE_KEY", "").strip()
    if not base_url or not publishable_key:
        raise HTTPException(status_code=503, detail="Supabase Auth is not configured")
    request = urllib.request.Request(
        f"{base_url}/auth/v1/user",
        headers={"apikey": publishable_key, "Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            user = json.loads(response.read())
    except urllib.error.HTTPError as exc:
        if exc.code in (400, 401, 403):
            raise HTTPException(status_code=401, detail="Sign-in expired; please sign in again") from exc
        raise HTTPException(status_code=503, detail="Supabase Auth is temporarily unavailable") from exc
    except (urllib.error.URLError, TimeoutError) as exc:
        raise HTTPException(status_code=503, detail="Supabase Auth is temporarily unavailable") from exc
    if not user.get("id") or not user.get("email"):
        raise HTTPException(status_code=401, detail="Supabase user identity is incomplete")
    return user


def profile_role(user: dict) -> str:
    """Create a pending profile or bootstrap the confirmed first coordinator."""
    email = user["email"].strip().casefold()
    bootstrap = os.getenv("SANKET_BOOTSTRAP_COORDINATOR_EMAIL", "").strip().casefold()
    first_role = "coordinator" if bootstrap and email == bootstrap and user.get("email_confirmed_at") else "pending"
    with db.session() as conn:
        conn.execute(
            "INSERT INTO user_roles(user_id,email,role,created_at) VALUES(?,?,?,?) "
            "ON CONFLICT(user_id) DO UPDATE SET email=excluded.email",
            (user["id"], email, first_role, utc_now()),
        )
        row = conn.execute("SELECT role FROM user_roles WHERE user_id=?", (user["id"],)).fetchone()
    return row["role"]


def actor_for(authorization: str | None = Header(default=None)) -> tuple[str, str]:
    """Authenticate Supabase sessions and resolve roles from the private role table."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Supabase sign-in required")
    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(status_code=401, detail="Supabase sign-in required")
    if os.getenv("SANKET_DEMO_TOKENS", "").casefold() == "true":
        for role, env_name in (("coordinator", "COORDINATOR_TOKEN"), ("responder", "RESPONDER_TOKEN")):
            expected = os.getenv(env_name, "")
            if expected and secrets.compare_digest(token, expected):
                return role, f"demo-{role}"
    if supabase_auth_configured():
        user = supabase_user_for_token(token)
        role = profile_role(user)
        if role == "pending":
            raise HTTPException(status_code=403, detail="Your account is awaiting coordinator approval")
        return role, user["email"]
    if os.getenv("SANKET_DEMO_TOKENS", "").casefold() == "true":
        raise HTTPException(status_code=401, detail="Invalid demo token")
    raise HTTPException(status_code=503, detail="Supabase Auth is not configured")


Actor = Annotated[tuple[str, str], Depends(actor_for)]


def require_coordinator(actor: Actor) -> tuple[str, str]:
    """Require coordinator access for review and record creation."""
    if actor[0] != "coordinator":
        raise HTTPException(status_code=403, detail="Coordinator role required")
    return actor


Coordinator = Annotated[tuple[str, str], Depends(require_coordinator)]
