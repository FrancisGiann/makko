# Makko mobile UI and motion contract

Phase 8 is a native Android-first Makko client. The mobile app shares the web app's Supabase schema, RLS policies, and GitHub Edge Function; it does not create a parallel backend contract.

## Structure

- `core/theme`: Material 3 light/dark schemes, Makko semantic status colors, typography, shapes, and persisted theme mode.
- `core/router`: GoRouter protected auth flow with session restoration, strict quick-capture links, and an adaptive NavigationBar/NavigationRail shell.
- `main.dart`: a branded bootstrap gate that restores the saved theme, initializes Supabase, and then reveals the authenticated/public app. Initialization errors can be retried; a timeout does not start a competing initialization.
- `features/auth`: email/password login and signup with validation and honest email-confirmation messaging.
- `features/dashboard`: internal Makko issue aggregation only.
- `features/projects`: project CRUD, project detail, internal issue CRUD/filter/sort/status actions, and activity feed.
- `features/github`: one owner/repository connection, manual read-only sync, recent commits, and open external issues.
- `services`: Supabase access and input normalization outside widgets.
- `providers`: Riverpod state and cache invalidation around the services.

Create/edit project and issue flows are full-screen routes. Filtering is a Material bottom sheet; destructive project/issue/GitHub actions use confirmation dialogs. Account/settings is reached from the top app bar rather than a global destination. A quick-capture intent is validated centrally, held while authentication redirects, and consumed once the shell is ready. The canonical Android URI is `makko://makko/capture`; only the known legacy `makko://capture?ref=widget` URI is also accepted. Unknown or malformed external links go to a safe recovery screen.

## Visual rules

Makko Cyan communicates action and active work. Deep Harbor layered surfaces form dark mode; Light Canvas and Paper form light mode. Emerald, amber, rose, and slate retain semantic meaning for done, medium priority, destructive/error, and todo states. Content is stacked and touch-first, with 48dp targets and safe keyboard/inset handling.

The mobile type scale uses Geist, matching the current product identity, with larger page titles, compact section labels, and tabular figures for counts. Geist regular, medium, semibold, and bold files are bundled under `mobile/assets/fonts/` under the SIL Open Font License; runtime font fetching is disabled. The dashboard opens with a compact greeting and name, a small friendly cyan shark, and a factual full-width summary of open internal work, followed by the metric strip and status, priority, and project workload sections. It does not equate high priority with urgency or describe the workspace in game-like copy. Project cards keep names and descriptions prominent, with tags and issue counts as secondary metadata. The project detail summary uses a compact three-column status readout. Light and dark themes share these roles and preserve semantic colors.

`MakkoMascot` is a small friendly cartoon shark drawn with Flutter canvas primitives rather than the green-backed raster asset. It has a rounded side-profile body, ivory underside, expressive eye, small smile, and independently articulated tail, dorsal fin, and pectoral fin. Its idle motion is quiet and a tap gives a brief bounded reaction. It stays still when its measured body is outside the dashboard viewport, when a route covers the shell, when the app is backgrounded, or when reduced-motion/accessibility settings request less movement. The persistent shell also disables tickers while covered. Project list rows appear immediately rather than waiting through per-index timers.

GoRouter pages use Flutter's platform Material transitions so Android Back and predictive Back remain native. Modal routes use a short upward transition and fall back to a fade when movement is disabled. Reduced motion and accessible navigation are observed while the mascot is mounted; startup transitions, shimmer, and empty-state entrances use the same policy. Refreshes preserve loaded data and expose inline retry feedback rather than replacing usable screens with a blank loading state.

The Android splash is a native vector wave mark, with Android 12+ splash attributes and matching day/night colors. It hands off to Flutter's startup surface without a raster mascot flash.

## Verification

Use the commands in [`mobile/README.md`](../mobile/README.md). Startup tests cover initialization failure/retry, a timed-out singleton initialization, disposal before late completion, theme restoration, and scaled short-screen retry reachability. Auth tests ensure signed-out/error events clear user-owned caches and cannot use a warmed restored-session ID to retain protected routes; they also exercise a successful auth event through GoRouter and map known credential, confirmation, rate-limit, and transient-connectivity errors without exposing unknown exception details. Quick-capture tests cover canonical/legacy/internal URI parity, strict malformed-link recovery, repeated taps after dismissal, and listener cleanup. Presentation tests cover bundled Geist availability with runtime fetching disabled, light/dark layouts, 320dp widths, 1.3 text scale, offscreen mascot pausing, reduced motion, route coverage, app lifecycle, and viewport resize. Final local checks completed with `flutter analyze --no-pub` (no issues) and `flutter test --no-pub` (76 tests passed). Debug and release APKs were built from this source at `mobile/build/app/outputs/flutter-apk/app-debug.apk` and `mobile/build/app/outputs/flutter-apk/app-release.apk`; release uses the repository's debug signing key and must be re-signed for distribution. The Flutter widget-render previews in `mobile/build/preview/` are 320×760 light/dark sample-data evidence, not Android device captures. No Android emulator or connected device was available, so native gesture behavior and frame timing remain unverified.
