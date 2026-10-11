import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/github/github_contribution_graph.dart';
import 'package:mobile/features/home_widgets/companion_widget_render.dart';
import 'package:mobile/features/home_widgets/heatmap_widget_render.dart';
import 'package:mobile/features/home_widgets/home_widget_manager.dart';
import 'package:mobile/features/home_widgets/quick_capture_queue.dart';
import 'package:mobile/models/dashboard_stats.dart';

void main() {
  group('HomeWidgetManager Constants & URI Parsing', () {
    test('defines required widget receiver names and keys', () {
      expect(
        HomeWidgetManager.quickCaptureWidget,
        'QuickCaptureWidgetReceiver',
      );
      expect(HomeWidgetManager.companionWidget, 'CompanionWidgetReceiver');
      expect(HomeWidgetManager.heatmapWidget, 'GithubHeatmapWidgetReceiver');

      expect(HomeWidgetManager.companionImageKey, 'companion_image');
      expect(HomeWidgetManager.heatmapImageKey, 'github_heatmap_image');

      expect(HomeWidgetManager.captureScheme, 'makko');
      expect(HomeWidgetManager.captureHost, 'makko');
      expect(HomeWidgetManager.capturePath, '/capture');
      expect(HomeWidgetManager.captureDeepLink, 'makko://makko/capture');
    });

    test('accepts only canonical and known legacy quick-capture links', () {
      expect(
        HomeWidgetManager.isCaptureUri(Uri.parse('makko://makko/capture')),
        isTrue,
      );
      expect(
        HomeWidgetManager.isCaptureUri(Uri.parse('makko://capture?ref=widget')),
        isTrue,
      );
      expect(
        HomeWidgetManager.isCaptureUri(Uri.parse('makko://dashboard')),
        isFalse,
      );
      expect(
        HomeWidgetManager.isCaptureUri(
          Uri.parse('makko://makko/capture?other=x'),
        ),
        isFalse,
      );
      expect(
        HomeWidgetManager.isCaptureUri(Uri.parse('makko://other/capture')),
        isFalse,
      );
      expect(
        HomeWidgetManager.isCaptureUri(Uri.parse('makko://capture')),
        isFalse,
      );
      expect(
        HomeWidgetManager.isCaptureUri(Uri.parse('https://makko.app/capture')),
        isFalse,
      );
      expect(HomeWidgetManager.isCaptureUri(null), isFalse);
    });

    test('dispatch listener accepts taps and cancels on disposal', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const methodChannel = MethodChannel('home_widget');
      const eventChannel = EventChannel('home_widget/updates');
      MockStreamHandlerEventSink? events;
      var cancellations = 0;
      messenger.setMockMethodCallHandler(methodChannel, (_) async => null);
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, sink) => events = sink,
          onCancel: (_) => cancellations++,
        ),
      );
      addTearDown(() {
        HomeWidgetManager.dispose();
        messenger.setMockMethodCallHandler(methodChannel, null);
        messenger.setMockStreamHandler(eventChannel, null);
      });

      var captureRequests = 0;
      await HomeWidgetManager.initialize(
        onQuickCapture: () => captureRequests++,
      );
      events!.success('makko://makko/capture');
      await Future<void>.delayed(Duration.zero);
      expect(captureRequests, 1);

      HomeWidgetManager.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cancellations, 1);
    });
  });

  group('QuickCaptureQueue', () {
    setUp(QuickCaptureQueue.resetForTest);

    test(
      'retains a recognized capture through auth redirect and consumes once',
      () {
        final accepted = QuickCaptureQueue.acceptCaptureLocation(
          Uri.parse('makko://makko/capture?ref=widget'),
        );
        expect(accepted, isTrue);
        expect(QuickCaptureQueue.hasPending, isTrue);

        expect(QuickCaptureQueue.consume(), isTrue);
        expect(QuickCaptureQueue.consume(), isFalse);
      },
    );

    test('accepts a fresh tap immediately after dismissal', () {
      expect(
        resolveCaptureRedirect(Uri.parse('makko://makko/capture')),
        '/dashboard',
      );
      expect(QuickCaptureQueue.consume(), isTrue);
      expect(
        resolveCaptureRedirect(Uri.parse('makko://makko/capture')),
        '/dashboard',
      );
      expect(QuickCaptureQueue.consume(), isTrue);
    });

    test('canonical, legacy, and internal routes share strict validation', () {
      for (final uri in [
        Uri.parse('makko://makko/capture'),
        Uri.parse('makko://capture?ref=widget'),
        Uri.parse('/capture?ref=widget'),
      ]) {
        expect(resolveCaptureRedirect(uri), '/dashboard');
        expect(QuickCaptureQueue.consume(), isTrue);
      }

      for (final uri in [
        Uri.parse('makko://evil/capture'),
        Uri.parse('makko://makko/capture/extra'),
        Uri.parse('makko://capture/extra?ref=widget'),
        Uri.parse('makko://makko/capture?ref=widget&ref=widget'),
      ]) {
        expect(resolveCaptureRedirect(uri), '/invalid-link');
        expect(QuickCaptureQueue.hasPending, isFalse);
      }
    });

    test('rejects other origins, unknown queries, and unrelated paths', () {
      expect(
        QuickCaptureQueue.acceptCaptureLocation(
          Uri.parse('https://makko.app/capture'),
        ),
        isFalse,
      );
      expect(
        QuickCaptureQueue.acceptCaptureLocation(
          Uri.parse('makko://evil/capture'),
        ),
        isFalse,
      );
      expect(
        QuickCaptureQueue.acceptCaptureLocation(
          Uri.parse('/capture?ref=other'),
        ),
        isFalse,
      );
      expect(
        QuickCaptureQueue.acceptCaptureLocation(Uri.parse('/projects')),
        isFalse,
      );
      expect(QuickCaptureQueue.hasPending, isFalse);
    });
  });

  group('CompanionWidgetRender Widget', () {
    testWidgets('renders companion avatar and status message', (tester) async {
      final stats = DashboardStats(
        projectCount: 1,
        totalIssues: 3,
        openIssues: 3,
        completedIssues: 0,
        byStatus: const {'todo': 3, 'in_progress': 0, 'done': 0},
        byType: const {'task': 3, 'bug': 0},
        byPriority: const {'low': 3, 'medium': 0, 'high': 0},
        projects: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CompanionWidgetRender(stats: stats, greeting: 'Afternoon'),
          ),
        ),
      );

      expect(find.text('M A K K O'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('3 active tasks remaining'), findsOneWidget);
      // expect(find.text('Makko Command Center'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders all-clear message when 0 open tasks', (tester) async {
      final stats = DashboardStats(
        projectCount: 1,
        totalIssues: 0,
        openIssues: 0,
        completedIssues: 0,
        byStatus: const {'todo': 0, 'in_progress': 0, 'done': 0},
        byType: const {'task': 0, 'bug': 0},
        byPriority: const {'low': 0, 'medium': 0, 'high': 0},
        projects: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(body: CompanionWidgetRender(stats: stats)),
        ),
      );

      expect(find.text('All clear! Ready to build.'), findsOneWidget);
    });
  });

  group('HeatmapWidgetRender Widget', () {
    testWidgets('renders GitHub activity header, grid, and cyan legend', (
      tester,
    ) async {
      final mockDays = List.generate(53 * 7, (index) {
        final col = index ~/ 7;
        final row = index % 7;
        return ContributionDay(
          date: '2025-09-14',
          level: (col + row) % 5,
          row: row,
          col: col,
        );
      });

      final data = GithubContributionsData(
        totalContributions: 342,
        days: mockDays,
        dateToLevel: {'2025-09-14': 1},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HeatmapWidgetRender(username: 'FrancisGiann', data: data),
          ),
        ),
      );

      expect(find.text('G I T H U B'), findsOneWidget);
      expect(find.text('Activity · @FrancisGiann'), findsOneWidget);
      expect(find.text('342 total'), findsOneWidget);
      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });
  });
}
