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

## Phase 3 web client

The React/Vite web client lives in [`web/`](web/). It currently provides the
Supabase email/password auth foundation and a protected account shell; product
features will be added in later phases.

```sh
cd web
npm install
cp .env.example .env.local
# Set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in .env.local.
npm run dev
```

Only the browser-safe Supabase URL and publishable key belong in the web
environment. Never place a Supabase secret/service-role key in `web/.env.local`
or any client-side source file. Use `npm run lint`, `npm run typecheck`,
`npm test`, and `npm run build` from `web/` for local checks.

In the Supabase Dashboard, configure Authentication → URL Configuration for
the environment you are running:

- Site URL: `http://localhost:5173` for local Vite development, or the exact
  production SPA origin such as `https://app.example.com` when deployed.
- Redirect URLs: allow the local SPA origins
  `http://localhost:5173/**` and `http://127.0.0.1:5173/**`, plus the exact
  production SPA origin with `/**` (for example,
  `https://app.example.com/**`).

Use the production origin as the Site URL in the production Supabase project;
use a separate local Supabase project or switch the value while developing
locally. These entries keep email-confirmation links and Supabase Auth
redirects inside the SPA. If the deployed host changes, update the Site URL
and allowed Redirect URLs together.
