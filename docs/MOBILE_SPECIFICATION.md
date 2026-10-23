# PROJECT: SANKET AI — COMPLETE FLUTTER MOBILE APPLICATION

## Engineering Role

Act as a Principal Flutter Engineer, Senior Mobile Application Architect, Forward Deployed Engineer, Backend Integration Engineer, Database Architect, Security Engineer, and QA Engineer with extensive experience designing and deploying reliable mobile applications.

Your mission is to build a complete, maintainable, secure, responsive, and backend-integrated Flutter application for SANKET AI.

Do not simply generate UI screens. Design the complete mobile experience, implement each page, connect every core action to the actual backend, configure the database safely, test real workflows, and document everything needed to run and maintain the application.

Execute the work in **Phase 0 followed by Phases 1–7**.

After every phase, produce a short engineering report containing implemented functionality, changed files, tests actually executed, known issues, and a six-parameter quality scorecard. Then continue automatically unless a genuine blocker prevents progress.

---

# PHASE 0 — GLOBAL INSTRUCTIONS, PROJECT RULES, AND ENGINEERING STANDARDS

This phase governs the entire project. Apply its instructions throughout every subsequent phase.

## 0.1. Product understanding

SANKET AI is an AI-assisted emergency-information processing and incident coordination platform.

The mobile application should allow authorized users to submit emergency reports, capture supporting evidence, view relevant incident information, receive assigned tasks, and update operational progress.

The application must work with the existing SANKET AI backend whenever one is available.

The mobile app must not become a disconnected product with separate incident records or conflicting business rules.

## 0.2. Mandatory engineering principles

- Inspect the existing repository before changing code.
- Preserve existing working features and user data.
- Reuse the existing backend, authentication provider, database schema, and API contracts wherever appropriate.
- Do not invent backend endpoints or claim an integration works without verification.
- Build features in small, testable increments.
- Keep presentation, application logic, data access, and domain models separate.
- Treat reports, uploaded files, API responses, and AI-generated content as untrusted data.
- Validate all important inputs and responses.
- Enforce permissions on the server, not just in the Flutter interface.
- Preserve original submitted reports and the provenance of extracted data.
- Distinguish AI proposals from verified information.
- Do not dispatch emergency resources or perform consequential operations through uncontrolled AI-only actions.
- Implement meaningful loading, empty, error, and recovery states.
- Never show success before the relevant backend operation has succeeded.
- Never claim a test passed unless it was actually executed successfully.
- Never claim deployment or third-party integration succeeded without evidence.

## 0.3. Mandatory evaluation criteria

Evaluate every phase against these six criteria.

### A. Code Quality
Use consistent naming, feature-based modularity, null safety, typed models, reusable widgets, manageable file sizes, and clear responsibility boundaries. Avoid unnecessary abstraction and duplicated logic.

### B. Security
Protect credentials, enforce authentication and authorization, secure evidence storage, use validated inputs, protect private records, and test unauthorized access attempts.

### C. Efficiency
Optimize API calls, data fetching, application startup, image handling, list rendering, pagination, synchronization, and background processing where measurable.

### D. Testing
Test business logic, repositories, widgets, authentication, database interactions, offline behavior, API failures, and complete user journeys.

### E. Accessibility
Use semantic widgets, screen-reader labels, sufficient contrast, scalable text, visible focus where applicable, accessible error messages, reduced-motion support, and usable touch targets.

### F. Problem Statement Alignment
Verify that each feature supports the actual SANKET AI requirements. Avoid unrelated features and unsupported claims.

At the end of each phase, score every criterion from 0 to 5, with concrete evidence supporting each score. Identify the weakest criterion and its next improvement. Critical security or data-integrity failures block phase completion.

## 0.4. Supabase credential rules

First inspect whether the repository contains a Supabase configuration and whether a Supabase connection or authorized project-management tool is available.

Use the following configuration model:

- `SUPABASE_URL`: The configured Supabase project URL.
- `SUPABASE_PUBLISHABLE_KEY`: The browser/mobile-safe publishable key, or the legacy anon key where applicable.
- `API_BASE_URL`: The existing backend API URL, if the application uses a separate FastAPI backend.

Keep local configuration out of version control.

For Flutter, use a suitable build configuration mechanism, such as `--dart-define-from-file`, and document the required variables. Remember that values bundled into a mobile binary are not secret merely because they originated from a configuration file.

**Never embed any of the following in the Flutter application:**

- Supabase service-role keys.
- Supabase secret keys.
- Database passwords.
- Privileged database connection strings.
- AI provider API keys.
- Server-only signing secrets.

If a privileged credential has already been exposed publicly or committed to source control, flag it for rotation.

Do not request that the user paste privileged credentials into source files or frontend code.

If project access is available, inspect the actual Supabase schema, tables, policies, storage buckets, and relationships before changing anything. If project access is unavailable, create migration files and precise setup instructions instead of pretending the remote database was modified.

## 0.5. Preserve backend architecture

Use the following integration priority:

1. Reuse the existing FastAPI or other backend API for report creation, incident management, task transitions, processing operations, and privileged business logic.
2. Use Supabase Auth for authentication if that is the existing identity system.
3. Use the Supabase Flutter client for direct database or storage operations only when they are intentionally supported by the existing architecture and protected by appropriate RLS policies.
4. Use backend endpoints or Edge Functions for privileged operations.
5. Keep repository interfaces independent of the specific data source so the implementation can evolve without rewriting the UI.

Do not bypass existing backend business rules by directly writing to database tables from the mobile app.

## 0.6. Report after every phase

Each report must include:

- Phase status: completed, partially completed, or blocked.
- Main features implemented.
- Important files added or modified.
- Database migrations or policies changed.
- Tests and commands actually executed.
- Failures and limitations.
- Code Quality score.
- Security score.
- Efficiency score.
- Testing score.
- Accessibility score.
- Problem Statement Alignment score.
- Next phase's concrete tasks.

Continue to the next phase unless blocked by a missing mandatory credential, unavailable service, destructive decision, or other genuine dependency.

---

# PHASE 1 — DISCOVERY, USER JOURNEYS, PAGE FLOW, AND APPLICATION ARCHITECTURE

## Objective

Understand the existing system and establish the complete Flutter experience before building individual screens.

## Step 1.1. Inspect the repository

Determine:

- Whether a Flutter application already exists.
- Current Flutter and Dart versions.
- Existing `pubspec.yaml` dependencies.
- Existing application entry point.
- Existing folders, routes, screens, widgets, and theme.
- Authentication implementation.
- Existing Supabase configuration.
- Existing backend API endpoints.
- Data models and response formats.
- Current database schema and migrations.
- Existing app assets and branding.
- Current test suite and run commands.

Do not replace functioning code until its purpose and limitations are understood.

## Step 1.2. Define the mobile application's users

Use the actual backend role model.

Potential roles are:

- Public report submitter.
- Authorized coordinator.
- Field responder.
- Administrator.

Do not create new roles unless the problem statement requires them.

Define the allowed actions for each role, particularly who can view private evidence, review extracted information, manage incidents, assign tasks, and change task states.

## Step 1.3. Establish the page flow

Design the following mobile navigation structure.

### Application startup and authentication

Splash / Initialization → Validate Local Session → Authentication or Authorized Home.

Unauthenticated public reporting may be supported if the backend permits it.

### Main authenticated navigation

Use a bottom navigation bar with four principal destinations:

1. **Home**
2. **Incidents**
3. **Tasks**
4. **Profile**

Provide an easy-to-reach **Report Emergency** action from the home screen and other justified entry points.

Avoid putting every page into the bottom navigation. Details pages and form pages should normally be reached through contextual navigation.

### Report submission journey

Home → Report Emergency → Describe Incident → Add Location → Attach Evidence → Review Submission → Submit → Confirmation.

Where the backend supports asynchronous processing:

Confirmation → Processing Status → Report Details / Review-Ready State.

### Field responder journey

Home → Assigned Tasks → Task Details → Associated Incident → Update Progress → Add Notes or Evidence → Submit Update → Refreshed Task Status.

### Incident exploration journey

Incidents → Search or Filter → Incident Details → Linked Reports / Location / Timeline → Related Tasks.

### Profile and settings journey

Profile → Account Information → Preferences → Language → Notification Preferences → Help / About → Sign Out.

Only implement settings that have actual behavior or a clearly scoped local preference.

## Step 1.4. Produce the route inventory

Use a routing package such as `go_router` and define route constants or a central route configuration.

Recommended routes:

| Screen | Route |
|---|---|
| Startup | `/splash` |
| Login | `/auth/login` |
| Registration, if supported | `/auth/register` |
| Password recovery, if supported | `/auth/forgot-password` |
| Home | `/app/home` |
| Report list | `/app/reports` |
| Create report | `/app/reports/new` |
| Report review before submission | `/app/reports/new/review` |
| Submission confirmation | `/app/reports/confirmation/:reportId` |
| Report details | `/app/reports/:reportId` |
| Saved drafts | `/app/reports/drafts` |
| Pending sync queue | `/app/reports/sync` |
| Incidents list | `/app/incidents` |
| Incident map, if supported | `/app/incidents/map` |
| Incident details | `/app/incidents/:incidentId` |
| Task list | `/app/tasks` |
| Task details | `/app/tasks/:taskId` |
| Notifications | `/app/notifications` |
| Profile | `/app/profile` |
| Settings | `/app/settings` |
| Language settings | `/app/settings/language` |
| Help | `/app/help` |
| Unauthorized state | `/unauthorized` |

Adjust the routes to match existing business requirements. Resolve static-versus-dynamic route conflicts and ensure protected routes remain protected after app restart or deep-link navigation.

## Step 1.5. Specify every screen

For each in-scope screen, define:

- Purpose.
- Primary user.
- Required information.
- Main actions.
- Backend dependencies.
- Required permissions.
- Loading state.
- Empty state.
- Failure state.
- Success state.
- Offline behavior.
- Acceptance criteria.

Do not build pages without defining how users reach them and how they return to their previous context.

## Phase 1 deliverables

Repository assessment, page-flow diagram, route inventory, role and permission matrix, architecture diagram, screen specifications, and initial integration plan.

### Mandatory Phase 1 report

Summarize the findings, page flow, route design, existing backend dependencies, risks, six quality scores, and Phase 2 plan.

---

# PHASE 2 — FLUTTER PROJECT FOUNDATION AND MAINTAINABLE ARCHITECTURE

## Objective

Create a stable mobile application foundation that supports the complete SANKET AI workflow.

## Step 2.1. Establish the Flutter project

Create or refine the Flutter project without deleting existing functionality.

Configure:

- Application name and identifiers.
- Supported platforms.
- Minimum platform requirements appropriate to the selected dependencies.
- Asset directories.
- Development and production configuration.
- Build flavors or environment-specific configuration where useful.
- Linting and formatting.
- Test infrastructure.

Run `flutter analyze` and the available test suite to establish a baseline.

## Step 2.2. Use a feature-first structure

Organize code by feature and separate the presentation, domain, and data responsibilities.

A suggested structure is:

```text
lib/
├── main.dart
├── bootstrap.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── route_paths.dart
│   └── app_shell.dart
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── constants/
│   ├── errors/
│   ├── network/
│   │   ├── api_client.dart
│   │   └── connectivity_service.dart
│   ├── security/
│   ├── theme/
│   ├── localization/
│   ├── permissions/
│   └── utils/
├── shared/
│   ├── widgets/
│   ├── models/
│   └── services/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── home/
│   ├── reports/
│   ├── incidents/
│   ├── tasks/
│   ├── notifications/
│   ├── profile/
│   └── settings/
├── offline/
│   ├── local_database/
│   ├── draft_store/
│   └── sync_manager/
└── generated/
```

Use this structure as a starting point, not as a requirement to create empty folders. Add files when functionality needs them.

## Step 2.3. Select state management

Use Riverpod or the existing state-management solution if already established.

Apply consistent patterns for:

- Authentication/session state.
- Dashboard data.
- Report forms and submission.
- Report lists and detail views.
- Incidents and map data.
- Tasks and transitions.
- Connectivity and synchronization.
- Settings and preferences.

Do not place all application state inside widgets or one global mutable object.

## Step 2.4. Establish navigation and UI foundations

Implement:

- Central route definitions.
- Authentication-aware navigation.
- Role-aware route access.
- Deep-link support where required.
- Error and not-found handling.
- Shared application shell.
- Theme system.
- Responsive layouts.
- Shared button and form styles.
- Reusable empty, loading, and error states.

## Step 2.5. Establish a component design system

Create reusable components for:

- Primary and secondary buttons.
- Form fields.
- Search fields.
- Status labels.
- Incident summaries.
- Task cards.
- Evidence tiles.
- Section headings.
- Progress indicators.
- Confirmation dialogs.
- Error panels.
- Retry actions.
- Offline and sync indicators.
- Reusable lists and cards.

Keep widgets small, testable, and semantically clear.

## Step 2.6. Add localization foundations

Use Flutter's localization system and keep user-facing strings out of business logic.

Support the languages required by the actual product requirements. At minimum, provide a structure that can accommodate English, Hindi, and Marathi when those languages are in scope.

Allow longer translations without layout overflow. Do not claim complete language support until the relevant screens, validation messages, and accessibility labels have been translated and tested.

## Phase 2 deliverables

A maintainable Flutter architecture, navigation foundation, theme, reusable widgets, environment configuration, and baseline automated checks.

### Mandatory Phase 2 report

Report the project structure, dependencies added, routing and theme status, actual build/analyze/test results, six quality scores, and Phase 3 plan.

---

# PHASE 3 — SUPABASE DATABASE, AUTHENTICATION, SECURITY, AND BACKEND INTEGRATION

## Objective

Connect the Flutter app to the actual SANKET AI backend and complete the required database work without exposing privileged credentials.

## Step 3.1. Inspect the Supabase project

If authorized Supabase project access is available:

- Inspect existing tables, columns, keys, indexes, and relationships.
- Inspect authentication settings and user metadata.
- Inspect existing RLS policies and grants.
- Inspect configured storage buckets.
- Inspect existing Edge Functions, if any.
- Determine whether a FastAPI backend already handles business operations.
- Identify missing schema or policy requirements.

Do not reset the project or drop existing tables. Do not replace existing schema merely to match a proposed design.

If direct access is unavailable, create SQL migrations, required configuration instructions, and a checklist that can be applied to the user's project.

## Step 3.2. Configure the Supabase client

Use the official `supabase_flutter` package, compatible with the repository's selected Flutter and Dart versions.

Initialize Supabase once during application bootstrap using:

- The configured project URL.
- The publishable key, or legacy anon key where applicable.

Load configuration using the chosen build configuration mechanism. Document how to configure development, testing, and production.

Remember that publishable keys identify the project rather than authenticate privileged operations. They must be paired with correct database privileges and RLS policies.

Never embed service-role keys, secret keys, database passwords, or AI provider credentials in Flutter.

## Step 3.3. Map the actual backend contracts

Before creating data-access implementations, establish a matrix:

| Feature | Data source | Required operation |
|---|---|---|
| Authentication | Existing identity provider | Sign in, sign out, session restoration |
| User profile | Existing API or authorized data access | Read/update permitted fields |
| Report submission | Existing backend API | Validate and persist report |
| Evidence | Private storage integration | Upload and authorized access |
| Report status | Report API or permitted query | Read processing state |
| AI extraction | Existing backend | Read validated result |
| Incident list | Existing incident API | Filter and paginate |
| Incident details | Existing incident API | Read permitted incident |
| Tasks | Existing task API | Read assignments and details |
| Task updates | Existing task API | Validate transitions |
| Notifications | Existing notification mechanism | Read and mark read |
| Offline drafts | Local storage | Save and synchronize drafts |

Use the actual endpoint paths and schema found in the repository.

If there is a FastAPI backend, use it for operations governed by its business rules. Direct Supabase data access is appropriate only for operations intentionally designed to use Supabase client access and backed by correct RLS and permissions.

## Step 3.4. Design the database safely

First reuse the existing schema. Where required entities do not exist, introduce versioned migrations for the minimum necessary structures.

Potential entities include:

**Profiles and memberships**
- `profiles`
- `organizations`
- `organization_members`

Only add organizational tables if the project needs organization-scoped users.

**Emergency reports**
- `reports`
- `evidence_assets`
- `processing_jobs`
- `extraction_results`

**Incident management**
- `incidents`
- `incident_reports`
- `incident_claims`, or an equivalent provenance/verification model

**Operations**
- `response_tasks`
- `notifications`, if required
- `audit_events`

Add foreign keys, uniqueness constraints, suitable timestamps, necessary indexes, and explicit status constraints as appropriate.

Use stable UUID identifiers where compatible with the existing schema.

Preserve source reports independently from incident records. Store versioned extraction results rather than overwriting original content.

## Step 3.5. Implement secure database access

For every table accessed by the mobile application:

- Enable RLS where the access model requires it.
- Define narrowly scoped policies for the intended roles.
- Grant only necessary table and function privileges.
- Validate record ownership and organization membership.
- Prevent public users from reading private reports.
- Prevent users from changing their own role to a privileged role.
- Prevent unauthorized evidence access.
- Prevent unauthorized task or incident updates.
- Ensure privileged operations cannot be achieved through unrestricted client queries.

Test both allowed and denied access scenarios.

Do not rely solely on frontend role checks.

## Step 3.6. Implement private evidence storage

If evidence is required, use a private bucket or the existing secure storage service.

Implement:

- Safe file naming.
- File type and size validation.
- Upload status.
- Ownership and report association.
- Authorized signed URLs or protected downloads.
- Upload failure recovery.
- Metadata persistence.
- Appropriate retention behavior.

Do not store large media files directly in ordinary database columns.

## Step 3.7. Implement migrations and data types

Keep SQL migrations under version control, using the repository's Supabase migration convention where applicable.

Provide migration commands and the procedure for inspecting generated changes.

If supported by the configured workflow, generate database types from the actual schema.

Do not claim that database changes have been applied remotely until successful execution is verified.

## Step 3.8. Build repository and service layers

Implement separate repositories or data sources for:

- Authentication.
- Profiles.
- Reports.
- Evidence.
- Incidents.
- Tasks.
- Notifications.
- Settings.
- Local drafts and synchronization.

Expose typed results to the UI. Normalize backend failures into meaningful application errors.

Do not put raw database queries or HTTP request logic directly into page widgets.

## Phase 3 deliverables

Configured Supabase access, verified backend mappings, version-controlled database changes where needed, working authentication, secure data access, and typed repositories.

### Mandatory Phase 3 report

Report inspected tables, migrations created or executed, RLS policies checked, authentication behavior, backend endpoints mapped, tests run, six quality scores, and Phase 4 plan.

---

# PHASE 4 — REPORT SUBMISSION, EVIDENCE CAPTURE, AND OFFLINE DRAFTS

## Objective

Implement the complete report creation workflow and make it resilient to device and network failures.

## Step 4.1. Home page — `/app/home`

Display only useful, permitted information, such as:

- Welcome message and account context.
- Quick report-submission action.
- Assigned tasks requiring attention.
- Relevant recent incidents.
- Pending report synchronization.
- Recent report-processing status.

Connect these sections to actual repositories. Do not populate the dashboard with hardcoded operational metrics.

## Step 4.2. Report list — `/app/reports`

Provide a paginated list of reports the current user is authorized to view.

Include:

- Report identifier.
- Short description.
- Submission time.
- Report status.
- Processing state.
- Sync status where relevant.
- Search or filters supported by the backend.
- Navigation to report details.

Support empty, loading, error, and offline states.

## Step 4.3. Create report — `/app/reports/new`

Use a manageable multi-step form rather than a single overloaded screen.

### Step A: Describe the emergency

Fields should reflect actual requirements, potentially including:

- Incident description.
- Incident category.
- Reported time.
- Relevant details.
- Required fields and validation.

### Step B: Add location

Support the location methods genuinely available to the app:

- Manually entered location description.
- Optional device location where permission has been granted.
- Latitude and longitude only when actually obtained from a supported source.
- A clear unresolved/unknown location state.

If GPS is unavailable or permission is denied, allow an appropriate manual workflow.

Never treat an inferred location as verified without adequate review.

### Step C: Attach evidence

Allow supported media capture or file selection.

Show:

- Allowed media types.
- File limits.
- Upload progress.
- Retry behavior.
- Removal of an attachment before submission.

Use least-privilege device permissions and request them only when needed.

### Step D: Review submission

Show a readable summary of the entered details, location information, and attached evidence.

Allow the user to go back and correct fields.

### Step E: Submit

Submit through the actual report backend.

Prevent accidental repeated submissions using suitable request identifiers or idempotency behavior.

If a network failure makes the outcome ambiguous, reconcile with the server or retry using the same idempotency key instead of generating duplicate reports.

## Step 4.4. Confirmation page — `/app/reports/confirmation/:reportId`

Display a server-confirmed receipt or report identifier, current known status, and next steps.

Clearly distinguish:

- Saved locally.
- Waiting to sync.
- Received by the server.
- Processing.
- Ready for review.
- Failed and requiring action.

Never display "successfully submitted" when the report exists only in local storage.

## Step 4.5. Report details — `/app/reports/:reportId`

Display:

- Original submitted information.
- Current report status.
- Permitted evidence previews.
- Processing state.
- Extracted AI summary if available.
- Location and its verification state.
- Relevant review status.

Clearly label AI-generated information as machine-generated and unconfirmed where appropriate.

## Step 4.6. Saved drafts — `/app/reports/drafts`

Allow users to view and edit unsent local drafts.

A draft must not be treated as a server-side report.

Allow the user to resume the form, remove a draft with appropriate confirmation, or submit it when online.

## Step 4.7. Pending synchronization — `/app/reports/sync`

Display:

- Pending uploads and submissions.
- Sync status.
- Last attempt.
- Recoverable errors.
- Retry actions.
- Items requiring user intervention.

Implement safe retry behavior and prevent duplicate creation.

## Step 4.8. Implement the offline workflow

Use local persistence suited to the project's requirements. Consider SQLite or Drift for structured drafts and pending synchronization; use lightweight preferences storage only for simple preferences.

When offline:

- Allow supported data to be saved as a draft.
- Clearly show local-only status.
- Preserve draft data through app restarts.
- Queue synchronization operations.
- Retry when connectivity returns.
- Avoid losing user-entered data after a failed request.

Do not promise background synchronization guarantees on every operating system. Use platform-appropriate scheduling and retry strategies.

## Step 4.9. Test reporting behavior

Test:

- Form validation.
- Evidence selection and rejected file types.
- Location permission denial.
- Report persistence.
- Repeated submit attempts.
- Offline draft creation.
- Process termination and restart.
- Failed upload recovery.
- Delayed server responses.
- Duplicate request handling.

## Phase 4 deliverables

Working report submission, evidence handling, report details, local drafts, and safe synchronization.

### Mandatory Phase 4 report

Report the complete reporting journey, working input modalities, offline capabilities, data-persistence tests, limitations, six quality scores, and Phase 5 plan.

---

# PHASE 5 — INCIDENTS, FIELD TASKS, STATUS UPDATES, AND MOBILE NAVIGATION

## Objective

Implement the core field-operations experience using real backend data and the correct role permissions.

## Step 5.1. Incidents list — `/app/incidents`

Build a clear list of incidents the authenticated user is allowed to view.

Include:

- Incident title or summary.
- Incident type.
- Current status.
- Location description where available.
- Review/verification indication.
- Related task information where useful.
- Search and supported filters.
- Loading, empty, and error states.

Use backend pagination when required.

## Step 5.2. Incident details — `/app/incidents/:incidentId`

Display:

- Incident summary.
- Status.
- Reported or verified location.
- Linked reports where permitted.
- Related evidence.
- Relevant claims and verification state.
- Incident activity timeline.
- Associated response tasks.
- Permitted action buttons.

Keep the distinction between reported, AI-inferred, and verified information visible.

Do not expose sensitive information outside the user's permission scope.

## Step 5.3. Incident map — `/app/incidents/map`

Only implement a map when location data and project requirements justify it.

Include:

- Real location coordinates.
- Clear status labels.
- A suitable incident-selection interaction.
- Navigation to incident details.
- Handling for incidents without verified coordinates.
- Loading and failure states.
- A textual alternative to the map.

Never fabricate pins or coordinates.

## Step 5.4. Task list — `/app/tasks`

Prioritize tasks assigned to the authenticated responder or otherwise available to the authorized role.

Include:

- Task title and description.
- Associated incident.
- Assignment information.
- Status.
- Relevant timestamps.
- Task-detail navigation.
- Empty, loading, error, and offline states.

Use useful filters such as task status when the backend supports them.

## Step 5.5. Task details — `/app/tasks/:taskId`

Display:

- Task details.
- Associated incident.
- Assignment.
- Current status.
- Relevant evidence and notes.
- Prior status changes.
- Actions allowed to the current user.

Enforce backend-defined transitions, such as:

`Assigned → In Progress → Completed`

Alternative states may include proposed, approved, rejected, or cancelled when required by the existing business model.

Do not implement unauthorized assignment or approval functionality.

## Step 5.6. Task updates

Support actual backend operations for allowed status changes and notes.

If field evidence can be attached to a task, associate the file with the correct incident or task through the approved backend workflow.

When offline actions are queued, show a pending-sync state. Do not present an unacknowledged update as confirmed by the server.

Handle stale versions and concurrent updates with a clear refresh or conflict-resolution experience.

## Step 5.7. Notifications — `/app/notifications`

If notification data exists, display relevant report-processing updates, incident changes, or assigned-task information.

Support read/unread state only when the backend provides the necessary capability.

For push notifications, inspect whether a push provider and server-side delivery flow are configured. Implement only a verifiable integration.

Avoid placing sensitive report contents in notification previews unnecessarily.

## Step 5.8. Profile and settings

### Profile — `/app/profile`

Display the authenticated user's permitted profile information and appropriate account actions.

### Settings — `/app/settings`

Add only genuine settings, such as language preference or notification preferences.

Persist settings in the chosen location. If a preference is local-only, identify it as a local preference rather than implying that it updates the server.

### Language — `/app/settings/language`

Implement the configured languages and preserve the selected preference. Confirm that layout, validation, and important operational labels work for longer translated strings.

## Step 5.9. Complete navigation integration

Connect all related pages:

- Dashboard → Reports.
- Reports → Report Details.
- Reports → Report Submission.
- Incidents → Incident Details.
- Incident Details → Related Reports and Tasks.
- Tasks → Task Details.
- Task Details → Associated Incident.
- Profile → Settings and Authentication Actions.

Verify back navigation, app restart, session restoration, deep links where required, and behavior when a selected record is unavailable.

## Phase 5 deliverables

A working incident-browsing, task-management, notification, profile, and settings experience with verified navigation.

### Mandatory Phase 5 report

Report implemented screens, backend connections, role enforcement, completed user journeys, test results, six quality scores, and Phase 6 plan.

---

# PHASE 6 — INTEGRATION HARDENING, TESTING, SECURITY, AND ACCESSIBILITY

## Objective

Verify that the Flutter app and its backend work together reliably.

## Step 6.1. Unit tests

Test:

- Model parsing and serialization.
- Form validation.
- Business rules.
- Repository behavior.
- Error mapping.
- Routing decisions.
- Sync queue behavior.
- Task transition validation where client-side validation is appropriate.

## Step 6.2. Widget tests

Test important screens for:

- Correct information display.
- Empty/loading/error states.
- Input validation.
- Button interactions.
- Navigation.
- Permission-dependent UI.
- Offline indicators.
- Accessibility semantics.

## Step 6.3. Integration tests

Test complete workflows against an appropriate test environment:

1. Sign in.
2. Create a report.
3. Upload evidence if supported.
4. Verify server persistence.
5. Retrieve report status.
6. Open an incident.
7. Retrieve assigned tasks.
8. Apply an authorized task transition.
9. Confirm the persisted result.
10. Attempt unauthorized actions and verify rejection.

Use mocks for isolated unit tests but do not treat mocked tests as proof of a real Supabase or backend integration.

## Step 6.4. Security review

Verify:

- No privileged keys in the application bundle.
- Correct configuration separation.
- Authentication and session expiration behavior.
- Appropriate RLS policies.
- Organization and role scoping.
- Private storage restrictions.
- Upload validation.
- Safe rendering of untrusted text.
- Authorization of incident/task changes.
- No privileged operation through unrestricted direct client access.
- Appropriate logging and error messages.

## Step 6.5. Offline and recovery tests

Simulate:

- Network disconnection.
- API timeout.
- Database or provider unavailability.
- Interrupted upload.
- App termination while a draft exists.
- Duplicate synchronization attempts.
- Expired authentication during synchronization.
- Concurrent updates.
- Invalid or stale record data.

Ensure that locally queued actions are never presented as server-confirmed until acknowledged.

## Step 6.6. Accessibility review

Check:

- Screen-reader labels.
- Semantics for buttons and status indicators.
- Text scaling.
- Contrast.
- Touch target sizes.
- Form-error comprehension.
- Reduced motion.
- Layout behavior for translated text.
- Keyboard navigation on supported platforms.
- Alternative text-based incident information when maps are used.

## Step 6.7. Performance review

Evaluate:

- App startup.
- Widget rebuilds.
- Large list scrolling.
- Image and file processing.
- Network request duplication.
- Data pagination.
- Offline database access.
- Synchronization behavior.
- Build size and dependency cost.

Use measurements where available instead of claiming improvements without evidence.

## Step 6.8. Run final project checks

Run actual applicable commands, such as:

- `flutter pub get`
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- Integration tests where configured.
- An Android debug or release build.
- An iOS build if a suitable macOS/Xcode environment is available.

Fix actionable failures, rerun the affected checks, and document anything that cannot run in the current environment.

## Phase 6 deliverables

A tested and hardened mobile application, integration results, security review, accessibility findings, performance observations, and a prioritized defect list.

### Mandatory Phase 6 report

Provide actual command outcomes, defects fixed, remaining blockers, six quality scores, and Phase 7 release-readiness steps.

---

# PHASE 7 — PRODUCTION CONFIGURATION, DEPLOYMENT READINESS, AND FINAL HANDOVER

## Objective

Prepare a reproducible Flutter release candidate and document the application so another developer can build and maintain it.

## Step 7.1. Production configuration

Document and validate:

- Supabase project URL.
- Supabase publishable key.
- Backend API base URL.
- Platform-specific configuration.
- Authentication redirect/deep-link settings where necessary.
- Storage permissions and setup.
- Notification configuration if implemented.
- Build flavors and platform identifiers.
- Required Android internet and runtime permissions.
- Required iOS permissions, including accurate usage descriptions.

Never include service-role keys, database credentials, or AI API keys in mobile configuration.

## Step 7.2. Database handover

Document:

- Tables and relationships actually used.
- Migrations created.
- RLS policies.
- Storage buckets and allowed operations.
- Required indexes.
- Required authentication settings.
- Commands for applying migrations.
- Safe database verification steps.
- Remaining manual setup tasks.

Confirm which schema changes were actually applied to the Supabase project versus merely generated as migration files.

## Step 7.3. Final application verification

Verify:

- Authentication and sign-out.
- Navigation and protected routes.
- Report persistence.
- Evidence access.
- Incident and task data.
- Offline drafts.
- Synchronization recovery.
- Authorization boundaries.
- Error and loading states.
- App build and tests.

Do not declare a feature complete unless it is implemented and verified to the extent stated in the report.

## Step 7.4. Write the README

Include:

- Project description.
- Architecture.
- Technology stack.
- Folder structure.
- Prerequisites.
- Configuration setup.
- Database and migration steps.
- Supabase setup.
- Authentication setup.
- Backend setup.
- Local run commands.
- Test commands.
- Android build instructions.
- iOS build instructions where supported.
- Offline behavior.
- Known limitations.
- Troubleshooting.
- Security notes.

Ensure every command matches the actual project.

## Step 7.5. Final delivery report

Provide:

1. Executive summary.
2. Implemented pages and routes.
3. Complete page-flow overview.
4. Folder structure.
5. Backend and Supabase integration details.
6. Database changes and RLS verification.
7. Offline and synchronization functionality.
8. Actual tests and build results.
9. Security and accessibility findings.
10. Six-parameter scorecard.
11. Known limitations.
12. Three highest-priority next steps.

Do not claim that the app is production-ready when required integrations, security checks, database policies, or release builds remain unverified.

---

# FINAL EXECUTION INSTRUCTION

Start now with Phase 1, under all rules established in Phase 0.

Inspect the existing Flutter repository and SANKET AI backend. Inspect the authorized Supabase project where available. Establish the complete page flow, data architecture, permissions, database mapping, and integration plan before implementing screens.

Then execute Phases 2–7 sequentially, providing the required short report after every phase.

Deliver a Flutter application in which the UI, database, authentication, offline drafts, synchronization, incidents, and field tasks form one coherent product.

Prioritize reliable report persistence, secure evidence handling, correct backend integration, accessible page flows, and honest operational status over decorative features or unverified claims.
