# SANKET AI engineering status

## Phase completion

| Phase | Status | Evidence and remaining work |
|---|---|---|
| 0 — Workspace and delivery setup | Complete | Project layout, dependency locks, API skeleton, docs, and local run instructions are present. No Git repository is initialized in this workspace. |
| 1 — Discovery and design | Complete for available inputs | Requirements were inferred from the supplied master prompt because there was no separate product brief. Traceability and workflow boundaries are documented. |
| 2 — Architecture and foundation | Complete for the prototype | FastAPI/Pydantic, private Postgres schema migration, SQLite test/demo adapter, worker, React/Vite/strict TypeScript client, and multi-stage container definition are present. |
| 3 — Intake, identity, and persistence | Implemented | Public report intake, Supabase Auth email/password flow, server token validation, pending/coordinator/responder roles, coordinator access panel, private role storage, and cloud database are wired. No org/tenant boundary or rate limiting. |
| 4 — AI processing | Implemented with bounded claims | Deterministic processing and optional consent-based Gemini extraction record source evidence and remain unverified. Provider calls were mocked; no live Gemini call or calibrated triage was done. |
| 5 — Landing and operator experience | Implemented | Public landing/report intake and operator auth/workspace are modular React components; account sign-in, confirmation guidance, reset/sign-out, pending approval, report review, incidents, tasks, audit and user-role management remain integrated. Map, uploads, realtime updates, and accessibility certification remain out of scope. |
| 6 — Integration and verification | Partial | Supabase migration applied, RLS verified on all nine app tables, security advisor returned no warnings, and cloud readiness passed through the session pooler. React typecheck, lint, and production build pass; hosted email/signup was not exercised with a real account; Docker is unavailable. |
| 7 — Deployment and handover | Partial | Environment sample, local runner, Docker Compose, README, and migration are complete. No public host/domain, deployment secrets, production email provider, backup schedule, or live operations run was configured. |

## Core acceptance rules

1. Persist original reports and a processing job atomically before returning a receipt.
2. Keep extraction output visibly unverified until a coordinator reviews it.
3. Keep reports and incidents separate; require an explicit coordinator decision to associate them.
4. Enforce roles on the API, not in browser controls. New accounts remain pending until approved.
5. Require coordinator approval and assignment before a responder can progress a task.
6. Never let AI output dispatch resources. This system does not dispatch resources.

## Verification

- The applied Supabase migration matches local history at `20261023054551_initial_schema`.
- `app_private` contains nine application tables; RLS is enabled on all nine and Supabase security advisors reported no issues.
- `GET /readyz` returned `{"status":"ready","database":"postgres"}` against the live project using its IPv4 session pooler.
- The database and publishable key are stored outside the repository in `~/.config/sanket-ai/supabase-project.env`; the browser config endpoint never returns the database URL.
- The pre-existing `sanket.db` was not read for records or copied to the hosted project.
- The backend suite passed earlier with 24 tests on Python 3.11 and 3.13; it was not rerun during this frontend migration.
- `npm run typecheck`, `npm run lint`, and `npm run build` pass. Vite emits route and auth chunks; the largest client chunk is below 300 kB.
- `npm audit` reported zero vulnerabilities after the React/Vite migration.
- Hosted sign-up, email confirmation, password reset delivery, and a real authenticated browser session were not exercised because no initial account email was provided.
- Local callback URLs on ports 5173 (Vite) and 8088 (FastAPI build) still need to be added to the Supabase Auth Redirect URLs allowlist. The supplied Management API token returned `403` for the Auth config update; a Dashboard update or token with Auth config write scope is required. The deployment origin must also be added before launch.
- Docker is unavailable, so Compose validation and image execution could not be performed.
- A legacy Supabase API key appeared in a CLI key-list response during setup. The application never uses that key. The attempt to disable legacy keys via Management API returned `403`; disable/rotate them from the Dashboard or use a token with API gateway key write scope.

## Remaining operational steps

1. Set `SANKET_BOOTSTRAP_COORDINATOR_EMAIL` to a confirmed email before its first app sign-in.
2. Add local and deployment callback URLs in Supabase Authentication → URL Configuration; choose the real HTTPS site URL when known.
3. Configure custom SMTP before wider account invitations; Supabase's default mail delivery is constrained for production use.
4. Provide deployment secrets privately, then deploy web and worker with the same `SUPABASE_DATABASE_URL`.
5. Disable/rotate unused legacy API keys, then add backup/restore, monitoring, retention, incident response, and a reviewed privacy/security operating process before real use.

## Known limits

This is a prototype, not a live emergency service. It has no data tenancy, rate limiting, evidence uploads, maps/geocoding, realtime feed, deployment host, or verified production posture. Text processing only prepares proposals and heuristic candidate lists. No report or AI output automatically triggers real-world response.
