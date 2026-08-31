# Makko Phase 1 database

This repository contains the Supabase database foundation for Makko.

Implemented:

- Projects owned by Supabase Auth users, with validated descriptions and tags.
- Issues with task/bug types, priorities, statuses, and immutable project ownership.
- Server-created project and issue activity history, including retained issue-delete entries.
- Per-project GitHub repository links and read-only synchronized commit/issue records.
- UUID primary keys, timestamp columns, foreign-key cascades, indexes, updated-at triggers, and RLS policies.
- Transactional pgTAP coverage for schema, constraints, RLS isolation, triggers, and cascades.

Run the database test suite from the repository root:

```sh
supabase test db
```

The complete schema and security contract are documented in [docs/DATABASE.md](docs/DATABASE.md).
