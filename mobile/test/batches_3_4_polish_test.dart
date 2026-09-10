import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/account/account_screen.dart';
import 'package:mobile/features/auth/login_screen.dart';
import 'package:mobile/features/auth/signup_screen.dart';
import 'package:mobile/features/github/github_connection_sheet.dart';
import 'package:mobile/features/projects/projects_screen.dart';
import 'package:mobile/models/dashboard_stats.dart';
import 'package:mobile/models/project.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/providers/projects_provider.dart';
import 'package:mobile/services/dashboard_service.dart';
import 'package:mobile/services/project_service.dart';
import 'package:mobile/widgets/empty_state.dart';
import 'package:mobile/widgets/priority_chip.dart';
import 'package:mobile/widgets/shimmer_loading.dart';
import 'package:mobile/widgets/status_chip.dart';

class _MockProjectService extends ProjectService {
  final List<Project> projects;
  _MockProjectService(this.projects);
  @override
  Future<List<Project>> listProjects(String ownerId) async => projects;
}

class _MockDashboardService extends DashboardService {
  final DashboardStats stats;
  _MockDashboardService(this.stats);
  @override
  Future<DashboardStats> getStats({String? ownerId}) async => stats;
}

void main() {
  group('Batch 3 - Router Parent Navigator Keys', () {
    testWidgets('router configuration contains parentNavigatorKey on subroutes', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      // Verify the shell route exists
      final shellRoute = router.configuration.routes
          .whereType<StatefulShellRoute>()
          .first;
      expect(shellRoute, isNotNull);

      // Find projects branch
      final projectBranch = shellRoute.branches[1];
      final projectsRoute = projectBranch.routes.first as GoRoute;
      expect(projectsRoute.path, '/projects');

      // Check subroutes under projects
      final newProjectRoute = projectsRoute.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == 'new');
      expect(newProjectRoute.parentNavigatorKey, isNotNull);

      final projectDetailRoute = projectsRoute.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == ':id');

      final editProjectRoute = projectDetailRoute.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == 'edit');
      expect(editProjectRoute.parentNavigatorKey, isNotNull);

      final newIssueRoute = projectDetailRoute.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == 'issues/new');
      expect(newIssueRoute.parentNavigatorKey, isNotNull);

      final editIssueRoute = projectDetailRoute.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == 'issues/:issueId/edit');
      expect(editIssueRoute.parentNavigatorKey, isNotNull);
    });
  });

  group('Batch 3 - LoginScreen Password Visibility Toggle', () {
    testWidgets('toggles password obscureText state on icon tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      final passwordFinder = find.widgetWithText(TextFormField, 'Password');
      expect(passwordFinder, findsOneWidget);

      EditableText editableText = tester.widget<EditableText>(
        find.descendant(of: passwordFinder, matching: find.byType(EditableText)),
      );
      expect(editableText.obscureText, isTrue);

      // Tap the toggle button
      final toggleFinder = find.byTooltip('Show password');
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pump();

      editableText = tester.widget<EditableText>(
        find.descendant(of: passwordFinder, matching: find.byType(EditableText)),
      );
      expect(editableText.obscureText, isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });
  });

  group('Batch 3 - SignupScreen Password Visibility Toggles', () {
    testWidgets('toggles both password and confirm password obscureText', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SignupScreen(),
        ),
      );

      final passwordFinder = find.widgetWithText(TextFormField, 'Password');
      final confirmFinder = find.widgetWithText(
        TextFormField,
        'Confirm password',
      );

      expect(passwordFinder, findsOneWidget);
      expect(confirmFinder, findsOneWidget);

      EditableText pwText = tester.widget<EditableText>(
        find.descendant(of: passwordFinder, matching: find.byType(EditableText)),
      );
      EditableText cpwText = tester.widget<EditableText>(
        find.descendant(of: confirmFinder, matching: find.byType(EditableText)),
      );
      expect(pwText.obscureText, isTrue);
      expect(cpwText.obscureText, isTrue);

      // Tap password toggle
      final pwToggle = find.descendant(
        of: passwordFinder,
        matching: find.byTooltip('Show password'),
      );
      await tester.tap(pwToggle);
      await tester.pump();

      pwText = tester.widget<EditableText>(
        find.descendant(of: passwordFinder, matching: find.byType(EditableText)),
      );
      expect(pwText.obscureText, isFalse);

      // Tap confirm password toggle
      final cpwToggle = find.descendant(
        of: confirmFinder,
        matching: find.byTooltip('Show password'),
      );
      await tester.tap(cpwToggle);
      await tester.pump();

      cpwText = tester.widget<EditableText>(
        find.descendant(of: confirmFinder, matching: find.byType(EditableText)),
      );
      expect(cpwText.obscureText, isFalse);
    });
  });

  group('Batch 3 - AccountScreen Theme Selector & Sign-out Dialog & Version', () {
    testWidgets('renders SegmentedButton for theme and shows sign out confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AccountScreen(),
          ),
        ),
      );

      // Check SegmentedButton
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // App version footer
      expect(find.text('Makko v1.0.0'), findsOneWidget);

      // Tap sign out to trigger dialog
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Sign out?'), findsOneWidget);
      expect(
        find.text("You'll need to sign in again to access your workspace."),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel dismisses dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('Batch 4 - StatusChip & PriorityChip Icons', () {
    testWidgets('StatusChip renders appropriate icons for statuses', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Column(
              children: const [
                StatusChip(status: 'todo'),
                StatusChip(status: 'in_progress'),
                StatusChip(status: 'done'),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('PriorityChip renders appropriate icons for priorities', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Column(
              children: const [
                PriorityChip(priority: 'high'),
                PriorityChip(priority: 'medium'),
                PriorityChip(priority: 'low'),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_double_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });

  group('Batch 4 - EmptyState animation and dashed border', () {
    testWidgets('EmptyState fades in and renders dashed border style', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Empty Inbox',
              subtitle: 'Nothing here yet',
              useDashedBorder: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Empty Inbox'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
    });
  });

  group('Batch 4 - ProjectsScreen Skeleton and Count Pills', () {
    testWidgets('renders skeleton while loading and workload count pills when loaded', (
      tester,
    ) async {
      final project = Project(
        id: 'p1',
        ownerId: 'u1',
        name: 'Project Alpha',
        description: 'Alpha description',
        tags: const ['core'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final stats = DashboardStats(
        projectCount: 1,
        totalIssues: 5,
        openIssues: 3,
        completedIssues: 2,
        byStatus: const {},
        byType: const {},
        byPriority: const {},
        projects: [
          ProjectSummary(
            id: 'p1',
            name: 'Project Alpha',
            total: 5,
            open: 3,
            completed: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authUserIdProvider.overrideWith((ref) => 'u1'),
            projectServiceProvider.overrideWith(
              (ref) => _MockProjectService([project]),
            ),
            dashboardServiceProvider.overrideWith(
              (ref) => _MockDashboardService(stats),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProjectsScreen(),
          ),
        ),
      );

      // Loading state shows ShimmerContainer
      expect(find.byType(ShimmerContainer), findsOneWidget);

      await tester.pump();
      await tester.pumpAndSettle();

      // Loaded state shows project title and pills
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('3 open'), findsOneWidget);
      expect(find.text('2 done'), findsOneWidget);
      expect(find.text('5 total'), findsOneWidget);
    });
  });

  group('Batch 4 - GithubConnectionSheet context.pop()', () {
    testWidgets('closes via close button', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/github'),
                child: const Text('Open Sheet'),
              ),
            ),
            routes: [
              GoRoute(
                path: 'github',
                builder: (_, _) => const GithubConnectionSheet(projectId: 'p1'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Connect GitHub'), findsOneWidget);

      // Tap close button (which calls context.pop())
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Connect GitHub'), findsNothing);
      expect(find.text('Open Sheet'), findsOneWidget);
    });
  });
}
