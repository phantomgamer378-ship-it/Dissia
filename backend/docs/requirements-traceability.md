# Requirements traceability and workflow design

## Discovery

The available source of product requirements is the supplied master engineering prompt. No separate product brief or deployment domain was present, so the workflow and prioritization below are inferred from that prompt.

## Traceability

| ID | Requirement | Priority | Acceptance evidence | Status |
|---|---|---:|---|---|
| R1 | Accept and durably acknowledge a public text report | P0 | Report and unique job insert in one transaction; receipt omits narrative text | Implemented |
| R2 | Preserve the source and record extraction provenance | P0 | Original text retained; versioned extraction and metadata records | Implemented |
| R3 | Require human review; AI cannot dispatch | P0 | Coordinator-only review route; all proposals labeled unverified; no dispatch action | Implemented |
| R4 | Keep report and incident records separate | P0 | Candidate suggestions require a reviewed report and explicit confirm/reject decision | Implemented |
| R5 | Propose, approve, assign, and progress tasks safely | P0 | API role guards, valid transitions, required assignee, optimistic version checks | Implemented |
| R6 | Record consequential operator actions | P1 | Audit table records role and workflow changes without copying report text | Implemented |
| R7 | Use individual identities and server-enforced roles | P0 | Supabase Auth sign-in, token validation, private user_roles table, pending approval | Implemented |
| R8 | Let coordinators manage new account access | P1 | Coordinator-only account list and role assignment UI/API | Implemented |
| R9 | Support durable background processing and retries | P1 | Worker lease/retry logic; PostgreSQL `SKIP LOCKED`, SQLite test/demo path | Implemented |
| R10 | Support optional grounded AI extraction | P1 | Google Gen AI SDK, opt-in, schema validation, repair/quarantine, provenance | Implemented; live provider call not made |
| R11 | Provide landing page, report intake, and responsive workspace | P1 | Root page, public form, receipts, operator views, semantic labels | Implemented; no accessibility certification |
| R12 | Deploy against managed database | P1 | Supabase project in Mumbai, versioned migration applied, nine tables under RLS | Implemented; backups/production deployment remain |
| R13 | Provide liveness and readiness endpoints | P1 | `/healthz`, `/readyz` checks configured database type | Implemented |
| R14 | Support evidence uploads, geospatial maps, and realtime data | P2 | No upload or map surface is exposed | Not implemented; absent from authoritative brief |

## Roles

| Action | Public | Pending | Responder | Coordinator |
|---|---:|---:|---:|---:|
| Submit a report and poll its receipt | Yes | Yes | Yes | Yes |
| Read reports, incidents, tasks, dashboard | No | No | Yes | Yes |
| Review reports, create incidents, propose/approve/assign tasks | No | No | No | Yes |
| Progress approved assigned tasks | No | No | Yes | Yes |
| Read audit history or manage account roles | No | No | No | Yes |

The browser cannot select or grant roles. A confirmed initial coordinator is bootstrapped from `SANKET_BOOTSTRAP_COORDINATOR_EMAIL`; all other new users begin pending. The coordinator API enforces authorization even if the browser is bypassed.

## Page and route flow

| Surface | Purpose | States and protections |
|---|---|---|
| `/` | Existing public landing, report form, and operator access | Validation, submission, receipt, sign-in/sign-up, password reset, pending approval, signed-in workspace |
| `POST /api/v1/reports` | Public text intake | Pydantic validation, idempotency, atomic persistence |
| `GET /api/v1/reports/{id}/receipt` | Public acknowledgment | Only id/status/time; no report text |
| `/api/v1/auth/me` | Supabase token validation and role lookup | 401 invalid/expired; pending user may only see own role state |
| `/api/v1/users` and `/api/v1/users/{id}/role` | Account administration | Coordinator-only; role changes audited; own coordinator role protected |
| `/api/v1/reports`, `/incidents`, `/tasks` | Operator work | Individual bearer token plus server role check |
| `/healthz`, `/readyz` | Process health and database readiness | Public, no private content |

## Architecture and data boundary

React/Vite client with strict TypeScript and Supabase JS → FastAPI → Auth token validation → role lookup → private PostgreSQL schema. React Router defines public and operator routes; TanStack Query manages server state. FastAPI and the worker connect directly to Postgres using the private database URL. The browser receives only the project URL and publishable key; it does not query `app_private` tables directly. The initial project migration is versioned in `supabase/migrations/`. Each application table has RLS enabled and has no grants for `anon` or `authenticated` Data API roles. Local tests use SQLite, including the `user_roles` table.

Public report text is untrusted source material. Gemini is called only when the report opted in and a key is configured. Extraction is an unverified proposal; the human review state is separate. Candidate matching uses shared words and exact submitted location text. It is a heuristic, not a probability score, geocoder, or automatic merge.

## Assumptions and remaining risks

- The product workflow was inferred from the master prompt and may need updates when an authoritative brief is supplied.
- The first coordinator email and deployment origin are still operator inputs; the project URL allowlist must include the local and deployment callbacks.
- Supabase default mail delivery is for setup/testing; configure trusted SMTP before wider use.
- Auth signup, email confirmation, password reset delivery, and hosted real-user flows have not been exercised yet.
- Postgres connection pooling, backup and restore validation, retention, rate limiting, organization tenancy, and production monitoring are not configured.
- No evidence uploads, maps, geocoding, real-time updates, calibrated triage, or live emergency dispatch are implemented.

## Phase status

See [engineering-status.md](engineering-status.md) for phase completion, verification evidence, and remaining deployment steps.
