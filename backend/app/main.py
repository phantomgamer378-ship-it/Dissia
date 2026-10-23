"""SANKET AI HTTP API and static operator interface."""

import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from app import auth, db
from app.auth import Actor, Coordinator
from app.routers import incidents, reports, tasks, users
from app.worker import process_one

STATIC = Path(__file__).parent / "static"
BUILT_FRONTEND = STATIC / "dist"


@asynccontextmanager
async def lifespan(_app: FastAPI):
    """Verify the configured durable database before serving requests."""
    db.initialize()
    yield


app = FastAPI(
    title="SANKET AI",
    version="0.1.0",
    description="Reviewable emergency report coordination prototype",
    lifespan=lifespan,
)

allowed_origins_env = os.getenv("ALLOWED_ORIGINS", "http://localhost:8088").strip()
origins = [o.strip() for o in allowed_origins_env.split(",") if o.strip()] or ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory=STATIC), name="static")

# Mount modular routers
app.include_router(users.router)
app.include_router(reports.router)
app.include_router(incidents.router)
app.include_router(tasks.router)


@app.api_route("/", methods=["GET", "HEAD"])
def home():
    """Serve the React frontend entry point."""
    return frontend_index()


@app.api_route("/healthz", methods=["GET", "HEAD"])
def healthz():
    """Return liveness status without checking downstream dependencies."""
    return {"status": "ok"}


@app.api_route("/readyz", methods=["GET", "HEAD"])
def readyz():
    """Check configured database availability for readiness probes."""
    try:
        with db.session() as conn:
            conn.execute("SELECT 1").fetchone()
        return {"status": "ready", "database": "postgres" if db.using_postgres() else "sqlite"}
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Database unavailable") from exc


@app.get("/api/v1/config")
def public_config():
    """Return browser-safe public capability settings; never return server secrets."""
    enabled = auth.supabase_auth_configured()
    return {
        "gemini_processing_enabled": bool(os.getenv("GEMINI_API_KEY", "").strip()),
        "supabase_auth_enabled": enabled,
        "supabase_url": os.getenv("SUPABASE_URL", "").strip() if enabled else None,
        "supabase_publishable_key": os.getenv("SUPABASE_PUBLISHABLE_KEY", "").strip() if enabled else None,
    }


@app.get("/api/v1/notifications")
def list_notifications(actor: Actor, limit: int = Query(20, ge=1, le=50)):
    """Return recent operational alerts and notifications from system audit events."""
    with db.session() as conn:
        rows = conn.execute(
            "SELECT id,actor,action,action AS title,target_type,target_id,created_at,detail AS body "
            "FROM audit ORDER BY created_at DESC LIMIT ?",
            (limit,),
        ).fetchall()
    return {"items": [dict(r) for r in rows]}


@app.get("/api/v1/dashboard/summary")
def dashboard(actor: Actor):
    """Return database-derived operational counts."""
    with db.session() as conn:
        counts = {
            "reports": conn.execute("SELECT COUNT(*) AS count FROM reports").fetchone()["count"],
            "needs_review": conn.execute("SELECT COUNT(*) AS count FROM reports WHERE reviewed=FALSE").fetchone()["count"],
            "open_incidents": conn.execute("SELECT COUNT(*) AS count FROM incidents WHERE status='OPEN'").fetchone()["count"],
            "active_tasks": conn.execute("SELECT COUNT(*) AS count FROM tasks WHERE status IN ('APPROVED','ASSIGNED','IN_PROGRESS')").fetchone()["count"],
        }
    return counts


@app.get("/api/v1/audit")
def audit_log(actor: Coordinator, limit: int = Query(100, ge=1, le=200)):
    """Return recent audit metadata without sensitive report content."""
    with db.session() as conn:
        rows = conn.execute("SELECT * FROM audit ORDER BY created_at DESC LIMIT ?", (limit,)).fetchall()
    return {"items": [dict(r) for r in rows]}


@app.post("/api/v1/worker/run-once")
def run_worker(actor: Coordinator):
    """Claim and process at most one queued report synchronously for local demos."""
    result = process_one()
    return result | {"message": "Report processed" if result.get("processed") else "No queued report"}


@app.get("/{path:path}", include_in_schema=False)
def frontend_fallback(path: str):
    """Serve the client-side routes while leaving unknown API paths as 404s."""
    if path == "api" or path.startswith("api/"):
        raise HTTPException(status_code=404, detail="Not found")
    return frontend_index()


def frontend_index():
    """Return the built frontend or a clear setup error when it has not been built."""
    index = BUILT_FRONTEND / "index.html"
    if not index.is_file():
        raise HTTPException(status_code=503, detail="Frontend build is missing; run npm run build.")
    return FileResponse(index)
