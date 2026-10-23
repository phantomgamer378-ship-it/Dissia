# SANKET AI — Flutter Mobile Application

An enterprise AI-assisted emergency information ingestion, verification, and coordinated field operations mobile application.

## System Architecture

```text
lib/
├── main.dart                                # Application entry point (orientations, UI overlay)
├── bootstrap.dart                           # Asynchronous initialization (Supabase, environment)
├── app/
│   ├── app.dart                             # MaterialApp.router with Riverpod and Localization
│   ├── app_shell.dart                       # Bottom navigation scaffold shell
│   ├── router.dart                          # GoRouter with authentication guards & role checks
│   └── splash_screen.dart                   # Animated splash screen with session verification
├── core/
│   ├── config/app_config.dart               # Environment variables via --dart-define-from-file
│   ├── constants/
│   │   ├── app_constants.dart               # Pagination, timeouts, mime types
│   │   └── route_paths.dart                 # Centralized type-safe route paths
│   ├── errors/                              # Domain error hierarchy and Result<T> pattern
│   ├── network/
│   │   ├── api_client.dart                  # Dio HTTP client with bearer tokens & interceptors
│   │   └── connectivity_service.dart        # Real-time online/offline monitoring
│   └── theme/app_theme.dart                 # Dark-mode theme with WCAG 2.2 contrast compliance
├── shared/
│   ├── models/                              # Domain models (User, Report, Incident, Task)
│   ├── screens/unauthorized_screen.dart     # RBAC access denial view
│   └── widgets/                             # StatusBadge, SanketButton, EmptyState, ErrorState
├── features/
│   ├── auth/                                # Supabase authentication + Demo token operator quick-login
│   ├── home/                                # Operator dashboard, metrics, quick actions
│   ├── reports/                             # Multi-step emergency reporting, reviews, receipt tracker
│   ├── incidents/                           # Operational incident tracking, task linking
│   ├── tasks/                               # Field response dispatch and state transitions
│   ├── profile/                             # Operator credentials and logout
│   ├── settings/                            # Language selection (EN, HI, MR) and system info
│   └── notifications/                       # Operational event alerts
└── offline/
    ├── draft_store/                         # Local draft storage for offline resiliency
    └── sync_manager/                        # Automatic synchronization queue with idempotency
```

## Running the Application

### 1. Running against Local SANKET AI Backend
```bash
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=DEBUG=true
```

### 2. Running Automated Tests & Linter
```bash
flutter analyze --no-pub
flutter test
```

## Backend Compatibility
This mobile application integrates directly with the SANKET AI FastAPI backend:
- `POST /api/v1/reports` (Atomic ingestion with `Idempotency-Key`)
- `GET /api/v1/reports/{report_id}/receipt` (Receipt tracking)
- `GET /api/v1/reports` (Operator list with bounded pagination)
- `GET /api/v1/reports/{report_id}` (Extraction and proposals)
- `POST /api/v1/reports/{report_id}/review` (Coordinator human verification)
- `POST /api/v1/reports/{report_id}/retry` (Requeue failed AI extraction jobs)
- `GET /api/v1/incidents` & `GET /api/v1/incidents/{id}` (Incident management)
- `GET /api/v1/tasks` & `PATCH /api/v1/tasks/{id}` (Field unit state machine)
