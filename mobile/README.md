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

## Verification

```sh
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
adb devices -l
```

## Manual Android checklist

- Sign up with a fresh email, confirm it if required, then sign in and sign out.
- Create, edit, refresh, open, and delete a project; confirm deletion is explicit.
- Create, edit, status-update, filter/sort, and delete internal task/bug issues.
- Confirm dashboard totals include internal issues only.
- Connect a valid `owner/repository`, sync, open a GitHub link, and disconnect; confirm external issues are labeled read-only.
- Toggle dark mode from Account, restart the app, and verify the choice persists.
- Test the system Back gesture, keyboard insets, narrow phone width, 1.3 font scale, and a wider window/landscape layout.
