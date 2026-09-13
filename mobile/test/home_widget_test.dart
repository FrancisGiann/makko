import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/github/github_contribution_graph.dart';
import 'package:mobile/features/home_widgets/companion_widget_render.dart';
import 'package:mobile/features/home_widgets/heatmap_widget_render.dart';
import 'package:mobile/features/home_widgets/home_widget_manager.dart';
import 'package:mobile/models/dashboard_stats.dart';

void main() {
  group('HomeWidgetManager Constants & URI Parsing', () {
    test('defines required widget receiver names and keys', () {
      expect(HomeWidgetManager.quickCaptureWidget, 'QuickCaptureWidgetReceiver');
      expect(HomeWidgetManager.companionWidget, 'CompanionWidgetReceiver');
      expect(HomeWidgetManager.heatmapWidget, 'GithubHeatmapWidgetReceiver');

      expect(HomeWidgetManager.companionImageKey, 'companion_image');
      expect(HomeWidgetManager.heatmapImageKey, 'github_heatmap_image');

      expect(HomeWidgetManager.captureScheme, 'makko');
      expect(HomeWidgetManager.captureHost, 'makko');
      expect(HomeWidgetManager.captureDeepLink, 'makko://makko');
    });

    test('isCaptureUri correctly identifies makko://capture deep link', () {
      expect(HomeWidgetManager.isCaptureUri(Uri.parse('makko://makko/capture')), isTrue);
      expect(HomeWidgetManager.isCaptureUri(Uri.parse('makko://capture?ref=widget')), isTrue);
      expect(HomeWidgetManager.isCaptureUri(Uri.parse('makko://dashboard')), isFalse);
      expect(HomeWidgetManager.isCaptureUri(Uri.parse('https://makko.app/capture')), isFalse);
      expect(HomeWidgetManager.isCaptureUri(null), isFalse);
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
            body: CompanionWidgetRender(
              stats: stats,
              greeting: 'Afternoon',
            ),
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
          home: Scaffold(
            body: CompanionWidgetRender(stats: stats),
          ),
        ),
      );

      expect(find.text('All clear! Ready to build.'), findsOneWidget);
    });
  });

  group('HeatmapWidgetRender Widget', () {
    testWidgets('renders GitHub activity header, grid, and cyan legend', (
      tester,
    ) async {
      final mockDays = List.generate(
        53 * 7,
        (index) {
          final col = index ~/ 7;
          final row = index % 7;
          return ContributionDay(
            date: '2025-09-14',
            level: (col + row) % 5,
            row: row,
            col: col,
          );
        },
      );

      final data = GithubContributionsData(
        totalContributions: 342,
        days: mockDays,
        dateToLevel: {'2025-09-14': 1},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HeatmapWidgetRender(
              username: 'FrancisGiann',
              data: data,
            ),
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
