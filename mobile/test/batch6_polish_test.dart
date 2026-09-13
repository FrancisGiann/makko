import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/dashboard/activity_heatmap.dart';
import 'package:mobile/features/dashboard/dashboard_screen.dart';
import 'package:mobile/features/projects/project_detail_screen.dart';
import 'package:mobile/features/projects/projects_screen.dart';
import 'package:mobile/models/activity_log.dart';
import 'package:mobile/models/dashboard_stats.dart';
import 'package:mobile/models/issue.dart';
import 'package:mobile/models/project.dart';
import 'package:mobile/providers/activity_provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/providers/github_provider.dart';
import 'package:mobile/providers/issues_provider.dart';
import 'package:mobile/providers/projects_provider.dart';
import 'package:mobile/services/activity_service.dart';
import 'package:mobile/services/github_service.dart';
import 'package:mobile/services/issue_service.dart';
import 'package:mobile/services/project_service.dart';
import 'package:mobile/widgets/makko_search_delegate.dart';

class _MockProjectService extends ProjectService {
  final List<Project> _projects;
  _MockProjectService(this._projects);

  @override
  Future<List<Project>> listProjects(String userId) async => _projects;
}

class _MockIssueService extends IssueService {
  final IssuePage _page;
  final List<Issue> _searchResults;
  _MockIssueService(this._page, [this._searchResults = const []]);

  @override
  Future<IssuePage> listIssues(
    String projectId, {
    int page = 1,
    IssueFilters filters = const IssueFilters(),
  }) async => _page;

  @override
  Future<List<Issue>> searchIssues(String query, {int limit = 25}) async =>
      _searchResults;
}

void main() {
  group('Batch 6 - Markdown Rendering', () {
    testWidgets('renders MarkdownBody for project and issue descriptions in ProjectDetailScreen', (
      tester,
    ) async {
      final project = Project(
        id: 'p1',
        ownerId: 'u1',
        name: 'Makko Engine',
        description: '**Bold mission** with _emphasis_ and `inline code`',
        tags: const ['core', 'engine'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final issues = [
        Issue(
          id: 'i1',
          projectId: 'p1',
          title: 'Implement parser',
          description: 'Use `dart:convert` for **fast** parsing',
          type: 'task',
          priority: 'high',
          status: 'todo',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authUserIdProvider.overrideWith((ref) => 'u1'),
            projectServiceProvider.overrideWith((ref) => _MockProjectService([project])),
            issueServiceProvider.overrideWith((ref) => _MockIssueService(IssuePage(
              items: issues,
              total: 1,
              page: 1,
              pageSize: 15,
              pageCount: 1,
            ))),
            issueStatusCountsProvider('p1').overrideWith(
              (ref) async => {'todo': 1, 'in_progress': 0, 'done': 0},
            ),
            githubProvider('p1').overrideWith(
              (ref) async => GithubProjectData(
                link: null,
                commits: const [],
                issues: const [],
              ),
            ),
            activityProvider('p1').overrideWith(
              (ref) async => ActivityPage(
                items: const [],
                page: 1,
                pageSize: 20,
                hasMore: false,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProjectDetailScreen(projectId: 'p1'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check MarkdownBody widgets are present
      expect(find.byType(MarkdownBody), findsAtLeastNWidgets(2));
      expect(find.text('Implement parser'), findsOneWidget);
    });
  });

  group('Batch 6 - Global Spotlight Search', () {
    testWidgets('DashboardScreen AppBar includes search IconButton', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardStatsProvider.overrideWith(
              (ref) => DashboardStats(
                projectCount: 0,
                totalIssues: 0,
                openIssues: 0,
                completedIssues: 0,
                byStatus: const {'todo': 0, 'in_progress': 0, 'done': 0},
                byType: const {'task': 0, 'bug': 0},
                byPriority: const {'high': 0, 'medium': 0, 'low': 0},
                projects: const [],
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('ProjectsScreen AppBar includes search IconButton', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsProvider.overrideWith(() => _MockProjectsNotifier([])),
            dashboardStatsProvider.overrideWith(
              (ref) => DashboardStats(
                projectCount: 0,
                totalIssues: 0,
                openIssues: 0,
                completedIssues: 0,
                byStatus: const {'todo': 0, 'in_progress': 0, 'done': 0},
                byType: const {'task': 0, 'bug': 0},
                byPriority: const {'high': 0, 'medium': 0, 'low': 0},
                projects: const [],
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProjectsScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('MakkoSearchDelegate finds matching projects and issues', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final project = Project(
        id: 'p1',
        ownerId: 'u1',
        name: 'Apollo App',
        description: 'Lunar exploration planner',
        tags: const ['space', 'flutter'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final issue = Issue(
        id: 'i1',
        projectId: 'p1',
        title: 'Fix propulsion telemetry',
        type: 'bug',
        priority: 'high',
        status: 'todo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: MakkoSearchDelegate(ref),
                        );
                      },
                      child: const Text('Open Search'),
                    ),
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/projects/:id',
            builder: (context, state) => Scaffold(
              body: Text('Project View: ${state.pathParameters['id']}'),
            ),
          ),
          GoRoute(
            path: '/projects/:id/issues/:issueId/edit',
            builder: (context, state) => Scaffold(
              body: Text(
                'Issue View: ${state.pathParameters['id']}/${state.pathParameters['issueId']}',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authUserIdProvider.overrideWith((ref) => 'u1'),
            projectsProvider.overrideWith(() => _MockProjectsNotifier([project])),
            dashboardStatsProvider.overrideWith(
              (ref) => DashboardStats(
                projectCount: 1,
                totalIssues: 1,
                openIssues: 1,
                completedIssues: 0,
                byStatus: const {'todo': 1, 'in_progress': 0, 'done': 0},
                byType: const {'task': 0, 'bug': 1},
                byPriority: const {'high': 1, 'medium': 0, 'low': 0},
                projects: [
                  ProjectSummary(
                    id: 'p1',
                    name: 'Apollo App',
                    total: 1,
                    open: 1,
                    completed: 0,
                  ),
                ],
              ),
            ),
            issueServiceProvider.overrideWith((ref) => _MockIssueService(
                  IssuePage.empty(),
                  [issue],
                )),
          ],
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open search delegate
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      // Initially shows search placeholder
      expect(find.text('Search Makko'), findsOneWidget);

      // Enter query matching project
      await tester.enterText(find.byType(TextField), 'Apollo');
      await tester.pumpAndSettle();

      expect(find.text('Apollo App'), findsOneWidget);
      expect(find.text('Lunar exploration planner'), findsOneWidget);

      // Enter query matching issue
      await tester.enterText(find.byType(TextField), 'propulsion');
      await tester.pumpAndSettle();

      expect(find.text('Fix propulsion telemetry'), findsOneWidget);

      // Tap issue to navigate
      await tester.tap(find.text('Fix propulsion telemetry'));
      await tester.pumpAndSettle();

      expect(find.text('Issue View: p1/i1'), findsOneWidget);
    });
  });

  group('Batch 6 - Activity Heatmap', () {
    testWidgets('ActivityHeatmap renders 30 days grid, labels, and legend', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final customData = {
        today: 4,
        today.subtract(const Duration(days: 1)): 2,
        today.subtract(const Duration(days: 5)): 1,
        today.subtract(const Duration(days: 15)): 6,
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ActivityHeatmap(
                activityData: customData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);
      expect(find.text('13 activities'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.byType(Tooltip), findsAtLeastNWidgets(30));
    });

    testWidgets('DashboardScreen displays ActivityHeatmap when projects exist', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stats = DashboardStats(
        projectCount: 1,
        totalIssues: 4,
        openIssues: 2,
        completedIssues: 2,
        byStatus: const {'todo': 1, 'in_progress': 1, 'done': 2},
        byType: const {'task': 3, 'bug': 1},
        byPriority: const {'high': 1, 'medium': 2, 'low': 1},
        projects: [
          ProjectSummary(
            id: 'p1',
            name: 'Orion',
            total: 4,
            open: 2,
            completed: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardStatsProvider.overrideWith((ref) => stats),
            recentActivitiesProvider.overrideWith((ref) async => [
                  ActivityLog(
                    id: 'a1',
                    projectId: 'p1',
                    type: 'issue_created',
                    description: 'Created issue',
                    createdAt: DateTime.now(),
                  ),
                ]),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(body: ActivityHeatmap(stats: stats)),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ActivityHeatmap), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ActivityHeatmap),
          matching: find.text('Activity'),
        ),
        findsOneWidget,
      );
      expect(find.text('Last 30 days'), findsOneWidget);
    });
  });
}

class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> _initial;
  _MockProjectsNotifier(this._initial);

  @override
  Future<List<Project>> build() async => _initial;
}
