import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/features/dashboard/dashboard_screen.dart';
import 'package:mobile/features/projects/create_issue_sheet.dart';
import 'package:mobile/features/projects/projects_screen.dart';
import 'package:mobile/models/dashboard_stats.dart';
import 'package:mobile/models/project.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/providers/projects_provider.dart';
import 'package:mobile/services/project_service.dart';
import 'package:mobile/widgets/makko_mascot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PresentationProjectService extends ProjectService {
  final List<Project> projects;

  _PresentationProjectService(this.projects);

  @override
  Future<List<Project>> listProjects(String ownerId) async => projects;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bundled Geist variants load with runtime fetching disabled', (
    tester,
  ) async {
    final previousRuntimeFetching = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() {
      GoogleFonts.config.allowRuntimeFetching = previousRuntimeFetching;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Column(
            children: [
              Text('Regular', style: TextStyle(fontWeight: FontWeight.w400)),
              Text('Medium', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('Semibold', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Bold', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final path in [
        'assets/fonts/Geist-Regular.ttf',
        'assets/fonts/Geist-Medium.ttf',
        'assets/fonts/Geist-SemiBold.ttf',
        'assets/fonts/Geist-Bold.ttf',
      ]) {
        expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
      }
    });
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  final project = Project(
    id: 'project-1',
    ownerId: 'user-1',
    name: 'Makko mobile command center',
    description: 'A focused place to keep the next release moving.',
    tags: const ['flutter', 'mobile', 'personal'],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
  final stats = DashboardStats(
    projectCount: 1,
    totalIssues: 8,
    openIssues: 5,
    completedIssues: 3,
    byStatus: const {'todo': 3, 'in_progress': 2, 'done': 3},
    byType: const {'task': 6, 'bug': 2},
    byPriority: const {'high': 1, 'medium': 3, 'low': 4},
    projects: [
      ProjectSummary(
        id: 'project-1',
        name: 'Makko mobile command center',
        total: 8,
        open: 5,
        completed: 3,
      ),
    ],
  );

  group('Makko mascot motion policy', () {
    testWidgets('reduced motion and disabled tickers settle without a loop', (
      tester,
    ) async {
      for (final media in [
        const MediaQueryData(disableAnimations: true),
        const MediaQueryData(accessibleNavigation: true),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: media,
              child: const Scaffold(body: MakkoMascot()),
            ),
          ),
        );
        await tester.pumpAndSettle(
          const Duration(milliseconds: 20),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 1),
        );
        expect(find.byType(MakkoMascot), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: TickerMode(
            enabled: false,
            child: Scaffold(body: MakkoMascot()),
          ),
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 20),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pauses when covered by a route or app backgrounding', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: const Center(child: MakkoMascot()),
              floatingActionButton: FloatingActionButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('Covered route')),
                    ),
                  ),
                ),
                child: const Icon(Icons.open_in_new),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 20),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 1),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 20),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 1),
      );

      expect(find.text('Covered route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Compact mobile presentation', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'dashboard and project rows fit 320dp at 1.3 text scale in both themes',
      (tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final media = MediaQueryData(
          size: const Size(320, 760),
          textScaler: const TextScaler.linear(1.3),
        );

        for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                dashboardStatsProvider.overrideWith((ref) async => stats),
              ],
              child: MaterialApp(
                theme: theme,
                home: MediaQuery(data: media, child: const DashboardScreen()),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 80));
          expect(find.byType(MakkoMascot), findsOneWidget);
          expect(find.text('Dashboard'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                authUserIdProvider.overrideWith((ref) => 'user-1'),
                projectServiceProvider.overrideWith(
                  (ref) => _PresentationProjectService([project]),
                ),
                dashboardStatsProvider.overrideWith((ref) async => stats),
              ],
              child: MaterialApp(
                theme: theme,
                home: MediaQuery(data: media, child: const ProjectsScreen()),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));
          expect(find.text(project.name), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('invalid-link recovery stays reachable on a short screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 240);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MakkoInvalidLinkScreen(),
        ),
      );

      final openMakko = find.text('Open Makko');
      await tester.ensureVisible(openMakko);
      expect(tester.takeException(), isNull);
      expect(openMakko, findsOneWidget);
    });

    testWidgets('issue form remains usable at 320dp and enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const CreateIssueSheet(projectId: 'project-1'),
          ),
        ),
      );

      expect(find.text('Capture the next piece of work'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('mascot loop stops when scrolled outside the viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            dashboardStatsProvider.overrideWith((ref) async => stats),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byType(MakkoMascot), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 20),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 2),
      );

      final layoutError = tester.takeException();
      if (layoutError is FlutterError) {
        debugPrint(
          layoutError.diagnostics.map((node) => node.toString()).join('\n'),
        );
      }
      expect(layoutError, isNull);
    });

    testWidgets('mascot visibility is recomputed when the viewport resizes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            dashboardStatsProvider.overrideWith((ref) async => stats),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      final mascot = tester.widget<MakkoMascot>(find.byType(MakkoMascot));
      expect(mascot.visible, isTrue);

      // Simulate a split-screen or orientation resize without scrolling.
      tester.view.physicalSize = const Size(360, 140);
      await tester.pump();
      await tester.pump();

      final resizedMascot = find.byType(MakkoMascot);
      if (resizedMascot.evaluate().isNotEmpty) {
        expect(tester.widget<MakkoMascot>(resizedMascot).visible, isFalse);
      }

      tester.view.physicalSize = const Size(360, 760);
      await tester.pump();
      await tester.pump();
      final restoredMascot = tester.widget<MakkoMascot>(
        find.byType(MakkoMascot),
      );
      expect(restoredMascot.visible, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
