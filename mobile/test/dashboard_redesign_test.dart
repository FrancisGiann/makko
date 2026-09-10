import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/dashboard/dashboard_screen.dart';
import 'package:mobile/models/dashboard_stats.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/widgets/shimmer_loading.dart';
import 'package:mobile/widgets/workspace_pulse_bar.dart';

void main() {
  group('ShimmerLoading', () {
    testWidgets('ShimmerContainer and ShimmerBox render with and without animations', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ShimmerContainer(
              child: ShimmerBox(width: 100, height: 20),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ShimmerBox), findsOneWidget);

      // Verify reduced motion / disabled animations
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: ShimmerContainer(
                child: ShimmerBox(width: 100, height: 20),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ShimmerBox), findsOneWidget);
    });
  });

  group('WorkspacePulseBar', () {
    testWidgets('renders 12 segments and progress percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: WorkspacePulseBar(completed: 6, total: 12),
          ),
        ),
      );

      expect(find.text('6 of 12 internal issues complete'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      // Find 12 segments
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Row).first,
          matching: find.byType(Container),
        ),
      );
      expect(containers.length, 12);
    });

    testWidgets('handles zero total issues gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: WorkspacePulseBar(completed: 0, total: 0),
          ),
        ),
      );

      expect(find.text('0 of 0 internal issues complete'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });
  });

  group('DashboardScreen', () {
    testWidgets('displays companion, metric strip, breakdowns, and workload when projects exist', (
      tester,
    ) async {
      final stats = DashboardStats(
        projectCount: 2,
        totalIssues: 5,
        openIssues: 3,
        completedIssues: 2,
        byStatus: const {'todo': 2, 'in_progress': 1, 'done': 2},
        byType: const {'task': 3, 'bug': 2},
        byPriority: const {'high': 1, 'medium': 2, 'low': 2},
        projects: [
          ProjectSummary(
            id: 'proj-1',
            name: 'Makko Mobile',
            total: 3,
            open: 2,
            completed: 1,
          ),
          ProjectSummary(
            id: 'proj-2',
            name: 'Makko Web',
            total: 2,
            open: 1,
            completed: 1,
          ),
        ],
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardStatsProvider.overrideWith((ref) => stats),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      // Pump through animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Page Title
      expect(find.text('Dashboard'), findsOneWidget);

      // High Alert mood because highPriority == 1
      expect(find.text('High Alert'), findsOneWidget);
      expect(find.textContaining('1 urgent item that needs attention'), findsOneWidget);

      // Metric strip counts
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('All Issues'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Breakdowns
      expect(find.text('By Status'), findsOneWidget);
      expect(find.text('By Priority'), findsOneWidget);

      // Workload
      expect(find.text('Project workload'), findsOneWidget);
      expect(find.text('Makko Mobile'), findsOneWidget);
      expect(find.text('Makko Web'), findsOneWidget);

      // Quick Actions
      expect(find.text('View projects'), findsOneWidget);
      expect(find.text('New project'), findsOneWidget);
    });

    testWidgets('displays empty state card when 0 projects exist', (
      tester,
    ) async {
      final emptyStats = DashboardStats(
        projectCount: 0,
        totalIssues: 0,
        openIssues: 0,
        completedIssues: 0,
        byStatus: const {'todo': 0, 'in_progress': 0, 'done': 0},
        byType: const {'task': 0, 'bug': 0},
        byPriority: const {'high': 0, 'medium': 0, 'low': 0},
        projects: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardStatsProvider.overrideWith((ref) => emptyStats),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ready to launch mood
      expect(find.text('Ready to launch'), findsOneWidget);
      expect(
        find.text(
          'Your workspace is ready. Create your first project and start tracking what matters.',
        ),
        findsOneWidget,
      );

      // Empty state card
      expect(find.text('Your workspace is empty'), findsOneWidget);
      expect(
        find.text('Create your first project to start tracking'),
        findsOneWidget,
      );
      expect(find.text('Create project'), findsOneWidget);
    });
  });
}
