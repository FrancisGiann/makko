# Makko mobile UI architecture note

Phase 8 ships a native Android-first “Pocket Tideboard” client. The mobile app shares the web app's Supabase schema, RLS policies, and GitHub Edge Function; it does not create a parallel backend contract.

## Structure

- `core/theme`: Material 3 light/dark schemes, Makko semantic status colors, typography, shapes, and persisted theme mode.
- `core/router`: GoRouter protected auth flow with session restoration and adaptive NavigationBar/NavigationRail shell.
- `features/auth`: email/password login and signup with validation and honest email-confirmation messaging.
- `features/dashboard`: internal Makko issue aggregation only.
- `features/projects`: project CRUD, project detail, internal issue CRUD/filter/sort/status actions, and activity feed.
- `features/github`: one owner/repository connection, manual read-only sync, recent commits, and open external issues.
- `services`: Supabase access and input normalization outside widgets.
- `providers`: Riverpod state and cache invalidation around the services.

Create/edit project and issue flows are full-screen routes. Filtering is a Material bottom sheet; destructive project/issue/GitHub actions use confirmation dialogs. Account/settings is reached from the top app bar rather than a global destination.

## Visual rules

Makko Cyan communicates action and active work. Deep Harbor layered surfaces form dark mode; Light Canvas and Paper form light mode. Emerald, amber, rose, and slate retain semantic meaning for done, medium priority, destructive/error, and todo states. Content is stacked and touch-first, with 48dp targets and safe keyboard/inset handling.

## Verification

Use the commands in [`mobile/README.md`](../mobile/README.md). The repository currently has no connected Android emulator/device evidence; static analysis, unit/widget tests, and debug/release APK builds are the attainable checks in this environment.
