import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'makko-theme';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({
    ThemeMode initialMode = ThemeMode.dark,
    bool restore = true,
  }) : super(initialMode) {
    if (restore) _restore();
  }

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_themeKey);
      if (stored == 'light' || stored == 'dark' || stored == 'system') {
        state = switch (stored) {
          'light' => ThemeMode.light,
          'system' => ThemeMode.system,
          _ => ThemeMode.dark,
        };
      }
    } catch (_) {
      // Theme persistence is best effort; the usable dark default remains.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themeKey, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      });
    } catch (_) {
      // Keep the in-memory selection if storage is unavailable.
    }
  }

  Future<void> toggle() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

Future<ThemeMode> loadSavedThemeMode() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
  } catch (_) {
    return ThemeMode.dark;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
