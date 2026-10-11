import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Makko startup gate', () {
    testWidgets(
      'shows a recoverable error and retries after initialization fails',
      (tester) async {
        var attempts = 0;
        await tester.pumpWidget(
          MakkoBootstrapGate(
            initialize: () async {
              attempts++;
              if (attempts == 1) throw StateError('offline');
              return ThemeMode.dark;
            },
            readyBuilder: (_) => const MaterialApp(
              home: Scaffold(body: Text('Ready workspace')),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Preparing Makko'), findsNothing);
        expect(find.textContaining('could not prepare'), findsOneWidget);
        expect(find.byKey(const ValueKey('makko-ready')), findsNothing);

        await tester.tap(find.text('Retry startup'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 260));

        expect(attempts, 2);
        expect(find.text('Ready workspace'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('retry shares the timed-out initialization until it settles', (
      tester,
    ) async {
      final initialization = Completer<ThemeMode>();
      var attempts = 0;
      await tester.pumpWidget(
        MakkoBootstrapGate(
          startupTimeout: const Duration(milliseconds: 10),
          initialize: () {
            attempts++;
            return initialization.future;
          },
          readyBuilder: (mode) =>
              MaterialApp(home: Scaffold(body: Text('Ready ${mode.name}'))),
        ),
      );
      await tester.pump(const Duration(milliseconds: 11));
      await tester.pump();
      expect(find.textContaining('taking longer'), findsOneWidget);

      await tester.tap(find.text('Retry startup'));
      await tester.pump();
      expect(attempts, 1);

      initialization.complete(ThemeMode.light);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('Ready light'), findsOneWidget);
      expect(attempts, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not reveal ready content after the gate is disposed', (
      tester,
    ) async {
      final initialization = Completer<ThemeMode>();
      var readyBuilds = 0;
      await tester.pumpWidget(
        MakkoBootstrapGate(
          initialize: () => initialization.future,
          readyBuilder: (_) {
            readyBuilds++;
            return const Text('Ready workspace');
          },
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      initialization.complete(ThemeMode.dark);
      await tester.pump();
      expect(readyBuilds, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('restores the stored theme before the ready surface appears', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'makko-theme': 'light'});
      await tester.pumpWidget(
        MakkoBootstrapGate(
          initialize: loadSavedThemeMode,
          readyBuilder: (mode) =>
              MaterialApp(home: Scaffold(body: Text('Ready ${mode.name}'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('Ready light'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('startup recovery stays reachable on a short scaled screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 380);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      var attempts = 0;
      await tester.pumpWidget(
        MakkoBootstrapGate(
          initialize: () async {
            attempts++;
            if (attempts == 1) throw StateError('offline');
            return ThemeMode.dark;
          },
          readyBuilder: (_) =>
              const MaterialApp(home: Scaffold(body: Text('Ready workspace'))),
        ),
      );
      await tester.pump();
      await tester.pump();

      final retryButton = find.text('Retry startup');
      await tester.ensureVisible(retryButton);
      expect(tester.takeException(), isNull);
      await tester.tap(retryButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(attempts, 2);
      expect(find.text('Ready workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
