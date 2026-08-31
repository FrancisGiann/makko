# Makko — AGENTS.md

## Project

Makko is a cross-platform personal command center for solo/indie developers managing multiple side projects.

It combines manually tracked projects, tasks/bugs, activity, dashboard stats, and read-only GitHub activity in one place.

This is a real portfolio-quality application, not a generic team task tracker.

Priorities:

1. Correctness
2. Security
3. Clean architecture
4. Maintainability
5. Good UX
6. Feature count

Avoid unnecessary complexity and scope creep.

---

## Fixed Stack

### Web
- React
- Vite
- TypeScript
- Tailwind CSS
- SPA only

### Mobile
- Flutter
- Dart
- Android target

### Backend
- Supabase
- PostgreSQL
- Supabase Auth
- Row-Level Security
- Supabase Edge Functions

### Other
- GitHub REST API
- Cloudflare Pages
- GitHub Actions

Everything should remain usable on free tiers.

Do not replace major technologies without asking.

---

## Repository

Expected structure:

```text
makko/
├── web/
├── mobile/
├── supabase/
├── docs/
├── .github/
├── AGENTS.md
└── README.md
```

Web and mobile are clients of the SAME Supabase backend.

Do not create separate backend logic for each client.

---

## Core Data Rules

Authentication uses Supabase `auth.users`.

### projects

Owned by one authenticated user.

Main fields:

- id
- owner_id
- name
- description
- tags (`text[]`)
- created_at
- updated_at

### issues

Tasks and bugs MUST use the same `issues` table.

Never create separate task and bug models/tables.

Exact enum values:

```text
type:
task
bug

priority:
low
medium
high

status:
todo
in_progress
done
```

Do not change these values without discussing it first.

### activity_log

Stores automatically generated project/issue activity.

Prefer database triggers for automatic activity generation.

### github_links

Connects one Makko project to one GitHub repository for the MVP.

### GitHub data

Synced GitHub commits and GitHub issues are READ-ONLY external data.

GitHub issues must remain separate from internal Makko issues.

Do not make GitHub issues affect internal dashboard statistics.

Use stable GitHub IDs/upserts to avoid duplicate sync data.

---

## Security

RLS is mandatory for user-owned data.

A user must never be able to access another user's:

- projects
- issues
- activity
- GitHub connections
- synced GitHub data

Do not trust frontend authorization alone.

Never expose:

- Supabase service-role keys
- GitHub secrets
- server credentials

GitHub sync must verify authentication and project ownership server-side.

Do not weaken existing RLS simply to make frontend development easier.

---

## Architecture

Keep UI and data access separated.

Preferred flow:

```text
UI
↓
hooks/state
↓
services/repositories
↓
Supabase
```

Do not scatter Supabase queries throughout React components or Flutter widgets.

Prefer simple architecture over unnecessary abstractions.

Before making a significant architectural change, explain the reason and ask.

---

## Web

Use a clean feature-oriented structure.

A reasonable starting point:

```text
web/src/
├── components/
├── features/
├── pages/
├── layouts/
├── services/
├── hooks/
├── types/
├── lib/
├── utils/
└── main.tsx
```

Adjust when useful, but keep responsibilities clear.

Use TypeScript properly. Avoid `any` unless there is a justified reason.

Handle:

- loading states
- empty states
- errors
- responsive layouts
- accessibility basics

---

## Flutter

Flutter uses the existing Makko backend.

Do not modify backend contracts simply to make Flutter easier.

Before Flutter implementation, discuss:

- state management
- navigation
- folder architecture

Do not silently choose a major state-management architecture.

Keep Supabase access outside UI widgets.

Use Dart null safety.

---

## MVP Features

Only these features are required:

1. Email/password authentication
2. Projects CRUD
3. Internal issues CRUD
4. Issue filtering/sorting
5. Dashboard statistics
6. Project activity feed
7. Dark/light theme
8. Read-only GitHub repository sync
9. Recent GitHub commits
10. Open GitHub issues

Dashboard statistics use INTERNAL Makko issues only.

Open:

```text
todo
in_progress
```

Completed:

```text
done
```

---

## Out of Scope

Do NOT build or scaffold unless explicitly requested:

- teams
- collaboration
- invites
- roles
- shared projects
- notifications
- FCM
- email reminders
- attachments
- screenshots
- milestones
- releases
- GitHub webhooks
- GitHub write-back
- pull request management
- comments
- chat
- AI features
- calendar
- deadlines
- time tracking
- billing
- subscriptions
- kanban boards

Do not add something simply because it is easy.

Ask first.

---

## UI Direction

Makko should look like a modern personal developer tool.

Prefer:

- clean interface
- useful information density
- modern typography
- strong dark mode
- simple navigation
- responsive design
- clear issue/status indicators
- subtle Makko/shark identity

Avoid:

- generic admin dashboard appearance
- Jira clone appearance
- school CRUD-system appearance
- excessive gradients/effects
- excessive shark/ocean theming

Web and Flutter should clearly feel like the same product.

---

## Testing

Add tests alongside important functionality.

Focus on:

- auth behavior
- services/repositories
- CRUD
- issue filters
- dashboard calculations
- security/RLS
- GitHub synchronization behavior

Run relevant tests/checks before declaring a phase complete.

Do not hide failing tests.

---

## Development Roadmap

### Phase 1 — Planning + Database
ERD, schema, constraints, indexes, and RLS.

### Phase 2 — Backend
Supabase migrations, policies, triggers, GitHub sync Edge Function, and backend testing.

### Phase 3 — Web Foundation + Auth
React/Vite/TypeScript/Tailwind setup, architecture, routing, Supabase client, service layer, authentication, session handling, and protected routes.

### Phase 4 — Web Core
Projects CRUD, issues CRUD, issue filtering/sorting, and project activity feed.

### Phase 5 — Web Experience
Dashboard statistics, GitHub integration UI, dark/light mode, loading/empty/error states, and responsive behavior.

### Phase 6 — Web Quality
Automated tests, security review, RLS verification, linting, type checking, accessibility basics, and bug fixing.

### Phase 7 — Web UI Polish + Deployment
Finalize and polish the completed web interface without changing established business logic or backend architecture.

Use the completed functional web app as the base for visual refinement.

After UI refinement, perform regression testing and deploy the web application to Cloudflare Pages.

The finished web application becomes the main visual and behavioral reference for the Flutter application.

### Phase 8 — Flutter Application
Before implementation, decide the Flutter state-management, navigation, and folder architecture.

Build the Flutter Android application using the existing Supabase backend.

Implement:

- authentication
- projects
- issues
- filtering/sorting
- dashboard
- activity
- GitHub integration
- dark/light theme

The Flutter application should feel like the same Makko product as the web application, but its interface should be properly adapted for mobile rather than directly copying desktop layouts.

Do not change established backend contracts simply to make Flutter implementation easier.

### Phase 9 — Final Quality + Documentation
Perform final cross-platform testing, CI/CD review, security review, cleanup, README completion, and documentation updates.

---

## Current Project Status

Completed:

- Phase 1 — Planning + Database
- Phase 2 — Backend

Current target:

- Phase 3 — Web Foundation + Auth

Do not redo completed phases unless inspection finds a real blocking problem.

---

## Working Rules

Before changing code:

1. Read this file.
2. Inspect the existing repository.
3. Understand existing implementation before replacing anything.

While working:

1. Work only on the requested phase/scope.
2. Preserve working backend architecture.
3. Keep changes focused.
4. Do not add out-of-scope features.
5. Do not silently make major architectural decisions.
6. Reuse existing code where appropriate.
7. Do not rewrite working code just for stylistic preference.

After working:

1. Run relevant lint/type/test checks.
2. Clearly report failures instead of hiding them.
3. Summarize what changed.
4. List important files changed.
5. Explain anything I need to configure manually.
6. Give me a short manual testing checklist.
7. Stop instead of automatically starting the next phase.