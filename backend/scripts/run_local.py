"""Run a local app/worker process with the project's private Supabase settings."""

import os
import stat
import sys
from pathlib import Path


def load_project_settings() -> None:
    """Load only Supabase connection settings from the mode-0600 config file."""
    config_path = Path.home() / ".config" / "sanket-ai" / "supabase-project.env"
    if not config_path.is_file():
        raise SystemExit(f"Missing private Supabase settings file: {config_path}")
    if stat.S_IMODE(config_path.stat().st_mode) & 0o077:
        raise SystemExit(f"Private Supabase settings file must not be accessible to group or other users: {config_path}")
    for line in config_path.read_text().splitlines():
        key, separator, value = line.partition("=")
        if separator and key in {"SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY", "SUPABASE_DATABASE_URL"}:
            os.environ.setdefault(key, value)
    required = ("SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY", "SUPABASE_DATABASE_URL")
    missing = [key for key in required if not os.environ.get(key)]
    if missing:
        raise SystemExit(f"Missing required Supabase setting(s): {', '.join(missing)}")


def main() -> None:
    load_project_settings()
    command = sys.argv[1:] or [
        "uvicorn", "app.main:app", "--reload", "--host", "127.0.0.1", "--port", os.getenv("SANKET_PORT", "8088")
    ]
    os.execvpe(command[0], command, os.environ)


if __name__ == "__main__":
    main()
