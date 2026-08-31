# Makko Phase 2 backend

This repository contains the Supabase database foundation and the secure
public-GitHub synchronization backend for Makko.

Implemented:

- Projects owned by Supabase Auth users, with validated descriptions and tags.
- Issues with task/bug types, priorities, statuses, and immutable project ownership.
- Server-created project and issue activity history, including retained issue-delete entries.
- Per-project GitHub repository links and read-only synchronized commit/issue records.
- UUID primary keys, timestamp columns, foreign-key cascades, indexes, updated-at triggers, and RLS policies.
- Transactional pgTAP coverage for schema, constraints, RLS isolation, triggers, and cascades.
- Service-role-only sync lifecycle RPCs with a persisted per-link lease,
  cooldown enforcement, atomic complete snapshot writes, deduplication,
  stale-row pruning, and sync timestamps.
- An authenticated `github-sync` Edge Function that verifies Supabase Auth
  sessions, authorizes project ownership, fetches public GitHub data, and
  writes only through the atomic RPC.
- Defensive request validation, SSRF-safe GitHub URL construction, CORS
  allowlisting, cooldown/rate-limit handling, and Deno unit coverage for pure
  mapping/fetch seams and HTTP failure paths.

The endpoint accepts `POST` JSON in this exact shape:

```json
{"project_id":"00000000-0000-0000-0000-000000000000"}
```

It returns `{ "data": ... }` on success and `{ "error": { "code", "message" } }`
on failure. Only public GitHub repositories are supported, without a GitHub
token. The unauthenticated GitHub API limit is IP-based, so this MVP uses a
short successful-sync cooldown and handles upstream rate-limit responses; a
future installation-auth or server-side GitHub credential is an explicit
tradeoff rather than part of Phase 2.

Run the database test suite from the repository root:

```sh
supabase test db
```

Run the Edge Function unit tests locally when Deno is installed:

```sh
deno fmt --check supabase/functions/github-sync
deno check --import-map supabase/functions/github-sync/import_map.json \
  supabase/functions/github-sync/index.ts supabase/functions/github-sync/github.ts
deno test --import-map supabase/functions/github-sync/import_map.json \
  supabase/functions/github-sync/github.test.ts
```

Deploy after applying migrations with the Supabase CLI:

```sh
supabase db push
supabase functions deploy github-sync
```

Configure `ALLOWED_ORIGINS` in the hosted function environment. Hosted
Supabase supplies `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEYS`, and
`SUPABASE_SECRET_KEYS`; local setups may use the legacy anonymous/service-role
names shown in [.env.example](.env.example). Never paste or commit real keys,
service secrets, or session JWTs.

The complete schema and security contract are documented in [docs/DATABASE.md](docs/DATABASE.md).
The request flow, trust boundaries, and deployment configuration are documented
in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
