# Makko mobile

The Makko Android client is a Flutter + Riverpod + GoRouter application backed by the same Supabase project as `web/`. It uses a Material 3 adaptive shell: NavigationBar on compact phones and NavigationRail on wider windows.

## Requirements

- Flutter SDK compatible with Dart 3.13+
- Android SDK/emulator or a connected Android device
- Access to the Makko Supabase project (the publishable key is safe for client apps; never use a service-role key)

## Run

From this directory:

```sh
flutter pub get
flutter run
```

The checked-in Supabase URL and publishable key provide a working default for the shared project. To use another environment, pass public client configuration at build/run time:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Email confirmation follows the Supabase project setting. When confirmation is enabled, signup tells the user to confirm their email before signing in.

## Startup and offline behavior

Makko shows its branded launch surface while it restores the saved theme and initializes the shared Supabase client. Protected routes do not appear until initialization and session restoration finish. A startup error has a retry action; a timeout keeps waiting on the original initialization rather than starting a second Supabase initialization. Geist is bundled locally under `assets/fonts/` with its OFL license, so the app does not fetch fonts at runtime. Network-backed data screens keep their last loaded content during refresh and show an inline retry when refresh fails.

The Android quick-capture widget opens `makko://makko/capture`. A known legacy widget link, `makko://capture?ref=widget`, is also accepted. Capture requests remain queued through sign-in and open once after the authenticated shell is ready; malformed external routes show a recoverable link screen.

## Verification

```sh
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
adb devices -l
```

Current debug and release APK outputs are in `build/app/outputs/flutter-apk/`. The release APK uses the repository's existing debug signing key; configure a private release key before publishing. The latest local analyzer and widget/unit suite pass; the light/dark widget-render previews are in `build/preview/`. No Android emulator or connected device was available for native gesture or frame-timing checks.

## Manual Android checklist

- Sign up with a fresh email, confirm it if required, then sign in and sign out.
- Create, edit, refresh, open, and delete a project; confirm deletion is explicit.
- Create, edit, status-update, filter/sort, and delete internal task/bug issues.
- Confirm dashboard totals include internal issues only.
- Connect a valid `owner/repository`, sync, open a GitHub link, and disconnect; confirm external issues are labeled read-only.
- Toggle dark mode from Account, restart the app, and verify the choice persists.
- Scroll the dashboard until the mascot leaves view, return to the top, tap the mascot, then background and resume the app; the idle loop should pause and restart without replaying list entrances.
- Enable Android's remove animations/reduced-motion setting while the dashboard is mounted, then rotate, resize to split-screen, and use 1.3 font scale.
- Rapidly open/close project and issue routes, use the system Back gesture/predictive Back, and confirm project tab/branch state and in-progress form values remain intact.
- Launch with network unavailable, verify the app reaches an honest retry state, restore connectivity, and retry without reopening the app. Also tap quick-capture while signed out and confirm the queued sheet opens once after sign-in; cancel it, then tap again immediately.
- Check keyboard insets, narrow phone width, and a wider window/landscape layout.
