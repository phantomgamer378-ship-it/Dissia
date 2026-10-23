"""SQLite development and private-schema PostgreSQL persistence."""

import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Any


def database_url() -> str:
    """Return the configured Supabase PostgreSQL connection URL, if present."""
    return os.getenv("SUPABASE_DATABASE_URL", "").strip()


def using_postgres() -> bool:
    """Report whether application queries should use the hosted PostgreSQL store."""
    return bool(database_url())


class PostgresConnection:
    """Adapt qmark SQL used by the application to psycopg parameter markers."""

    def __init__(self, connection: Any):
        self.connection = connection

    def execute(self, query: str, parameters: tuple | list = ()):
        return self.connection.execute(query.replace("?", "%s"), parameters)

    def __getattr__(self, name: str):
        return getattr(self.connection, name)


def connect():
    """Open a dictionary-row connection to Supabase or the local SQLite file."""
    url = database_url()
    if url:
        import psycopg
        from psycopg.rows import dict_row

        connection = psycopg.connect(
            url,
            row_factory=dict_row,
            options="-c search_path=app_private,public",
        )
        return PostgresConnection(connection)
    db = sqlite3.connect(os.getenv("SANKET_DB_PATH", "./sanket.db"), timeout=10)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA foreign_keys = ON")
    return db


@contextmanager
def session():
    """Yield a transaction-scoped connection and always close it."""
    connection = connect()
    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def initialize() -> None:
    """Initialize local SQLite tables or verify that the hosted migration exists."""
    if using_postgres():
        with session() as conn:
            if not conn.execute("SELECT to_regclass('app_private.reports') AS reports").fetchone()["reports"]:
                raise RuntimeError("Supabase schema is missing; apply the committed migration with supabase db push")
        return

    path = Path(os.getenv("SANKET_DB_PATH", "./sanket.db"))
    path.parent.mkdir(parents=True, exist_ok=True)
    with session() as db:
        db.executescript(
            """
            PRAGMA journal_mode = WAL;
            CREATE TABLE IF NOT EXISTS reports (
              id TEXT PRIMARY KEY, description TEXT NOT NULL, location TEXT,
              received_at TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'QUEUED',
              urgency TEXT NOT NULL DEFAULT 'UNKNOWN', extraction_json TEXT,
              processing_metadata_json TEXT, ai_consent INTEGER NOT NULL DEFAULT 0,
              reviewed INTEGER NOT NULL DEFAULT 0
            );
            CREATE TABLE IF NOT EXISTS jobs (
              id INTEGER PRIMARY KEY AUTOINCREMENT, report_id TEXT NOT NULL UNIQUE
                REFERENCES reports(id), status TEXT NOT NULL DEFAULT 'QUEUED',
              attempts INTEGER NOT NULL DEFAULT 0, available_at TEXT NOT NULL,
              lease_until TEXT, last_error TEXT
            );
            CREATE INDEX IF NOT EXISTS jobs_claim_idx ON jobs(status, available_at);
            CREATE TABLE IF NOT EXISTS idempotency_keys (
              key TEXT PRIMARY KEY, report_id TEXT NOT NULL REFERENCES reports(id)
            );
            CREATE INDEX IF NOT EXISTS reports_received_idx ON reports(received_at DESC);
            CREATE TABLE IF NOT EXISTS incidents (
              id TEXT PRIMARY KEY, title TEXT NOT NULL, summary TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'OPEN', location TEXT,
              created_at TEXT NOT NULL, version INTEGER NOT NULL DEFAULT 1
            );
            CREATE TABLE IF NOT EXISTS associations (
              report_id TEXT NOT NULL REFERENCES reports(id),
              incident_id TEXT NOT NULL REFERENCES incidents(id),
              state TEXT NOT NULL DEFAULT 'CONFIRMED', created_at TEXT NOT NULL,
              PRIMARY KEY(report_id, incident_id)
            );
            CREATE TABLE IF NOT EXISTS extraction_records (
              id TEXT PRIMARY KEY, report_id TEXT NOT NULL REFERENCES reports(id),
              version INTEGER NOT NULL, provider TEXT NOT NULL, model TEXT,
              prompt_hash TEXT, schema_version TEXT NOT NULL,
              validation_state TEXT NOT NULL, duration_ms INTEGER NOT NULL,
              token_usage_json TEXT, result_json TEXT NOT NULL, created_at TEXT NOT NULL,
              UNIQUE(report_id,version)
            );
            CREATE TABLE IF NOT EXISTS tasks (
              id TEXT PRIMARY KEY, incident_id TEXT NOT NULL REFERENCES incidents(id),
              title TEXT NOT NULL, description TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'PROPOSED', assignee TEXT,
              created_at TEXT NOT NULL, version INTEGER NOT NULL DEFAULT 1
            );
            CREATE TABLE IF NOT EXISTS audit (
              id INTEGER PRIMARY KEY AUTOINCREMENT, actor TEXT NOT NULL,
              action TEXT NOT NULL, target_type TEXT NOT NULL, target_id TEXT NOT NULL,
              created_at TEXT NOT NULL, detail TEXT
            );
            CREATE TABLE IF NOT EXISTS user_roles (
              user_id TEXT PRIMARY KEY, email TEXT NOT NULL,
              role TEXT NOT NULL CHECK(role IN ('pending','coordinator','responder')),
              created_at TEXT NOT NULL
            );
            """
        )
        columns = {row["name"] for row in db.execute("PRAGMA table_info(reports)")}
        if "processing_metadata_json" not in columns:
            db.execute("ALTER TABLE reports ADD COLUMN processing_metadata_json TEXT")
        if "ai_consent" not in columns:
            db.execute("ALTER TABLE reports ADD COLUMN ai_consent INTEGER NOT NULL DEFAULT 0")
        task_cols = {row["name"] for row in db.execute("PRAGMA table_info(tasks)")}
        if "notes" not in task_cols:
            db.execute("ALTER TABLE tasks ADD COLUMN notes TEXT")


def row_dict(row: sqlite3.Row | dict[str, Any] | None) -> dict[str, Any] | None:
    """Convert a SQLite or PostgreSQL row to a JSON-friendly dictionary."""
    return dict(row) if row else None
