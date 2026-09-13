import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/dashboard/dashboard_screen.dart';
import 'package:mobile/features/dashboard/global_create_issue_sheet.dart';
import 'package:mobile/features/github/github_contribution_graph.dart';
import 'package:mobile/features/projects/project_detail_screen.dart';
import 'package:mobile/models/dashboard_stats.dart';
import 'package:mobile/models/issue.dart';
import 'package:mobile/models/project.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/providers/issues_provider.dart';
import 'package:mobile/providers/projects_provider.dart';
import 'package:mobile/services/dashboard_service.dart';
import 'package:mobile/services/issue_service.dart';
import 'package:mobile/services/project_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockProjectService extends ProjectService {
  final List<Project> _projects;
  _MockProjectService(this._projects);

  @override
  Future<List<Project>> listProjects(String userId) async => _projects;
}

class _MockIssueService extends IssueService {
  final List<Issue> _issues;
  _MockIssueService(this._issues);

  @override
  Future<IssuePage> listIssues(
    String projectId, {
    int page = 1,
    IssueFilters filters = const IssueFilters(),
  }) async {
    return IssuePage(
      items: _issues,
      page: 1,
      pageSize: 15,
      pageCount: 1,
      total: _issues.length,
    );
  }

  @override
  Future<Issue> createIssue(
    String projectId, {
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
  }) async {
    final newIssue = Issue(
      id: 'issue-new-${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      title: title,
      description: description,
      type: type,
      priority: priority,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _issues.add(newIssue);
    return newIssue;
  }

  @override
  Future<Issue> updateIssue(
    String projectId,
    String issueId, {
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
  }) async {
    final index = _issues.indexWhere((i) => i.id == issueId);
    if (index != -1) {
      final updated = Issue(
        id: issueId,
        projectId: projectId,
        title: title,
        description: description,
        type: type,
        priority: priority,
        status: status,
        createdAt: _issues[index].createdAt,
        updatedAt: DateTime.now(),
      );
      _issues[index] = updated;
      return updated;
    }
    throw Exception('Issue not found');
  }
}

class _MockDashboardService extends DashboardService {
  final DashboardStats _stats;
  _MockDashboardService(this._stats);

  @override
  Future<DashboardStats> getStats({String? ownerId}) async => _stats;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final defaultStats = DashboardStats(
    projectCount: 1,
    totalIssues: 1,
    openIssues: 1,
    completedIssues: 0,
    byStatus: const {'todo': 1, 'in_progress': 0, 'done': 0},
    byType: const {'task': 1, 'bug': 0},
    byPriority: const {'low': 1, 'medium': 0, 'high': 0},
    projects: [
      ProjectSummary(id: 'proj-1', name: 'Test', total: 1, open: 1, completed: 0),
    ],
  );

  group('Batch 7 - Quick-Swipe Priority Changes & Mark Done', () {
    testWidgets(
      'Left-to-Right swipe cycles priority and Right-to-Left swipe marks as done',
      (tester) async {
        final project = Project(
          id: 'proj-1',
          ownerId: 'u1',
          name: 'Swipe Test Project',
          tags: const ['test'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final issue = Issue(
          id: 'issue-1',
          projectId: 'proj-1',
          title: 'Quick Swipe Test Issue',
          type: 'task',
          priority: 'low',
          status: 'todo',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final issueService = _MockIssueService([issue]);

        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authUserIdProvider.overrideWith((ref) => 'u1'),
              dashboardStatsProvider.overrideWith((ref) => defaultStats),
              projectServiceProvider
                  .overrideWith((ref) => _MockProjectService([project])),
              issueServiceProvider.overrideWith((ref) => issueService),
              issueStatusCountsProvider('proj-1').overrideWith(
                (ref) async => {'todo': 1, 'in_progress': 0, 'done': 0},
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const ProjectDetailScreen(projectId: 'proj-1'),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify issue card is rendered
        expect(find.text('Quick Swipe Test Issue'), findsOneWidget);

        // Find dismissible widget by key
        final dismissibleFinder = find.byKey(const Key('issue-issue-1'));
        expect(dismissibleFinder, findsOneWidget);

        // Verify background has amber color and flag icon (leading / Left-to-Right)
        final dismissibleWidget = tester.widget<Dismissible>(dismissibleFinder);
        expect(dismissibleWidget.background, isNotNull);
        expect(dismissibleWidget.secondaryBackground, isNotNull);

        // Swipe Left-to-Right (startToEnd): cycles priority from low -> medium
        await tester.fling(dismissibleFinder, const Offset(600, 0), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Verify priority was updated to medium in the mock service
        expect(issueService._issues.first.priority, 'medium');

        // Swipe Left-to-Right again: cycles priority from medium -> high
        await tester.fling(find.byKey(const Key('issue-issue-1')).last, const Offset(600, 0), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(issueService._issues.first.priority, 'high');

        // Swipe Right-to-Left (endToStart): marks as done
        await tester.fling(find.byKey(const Key('issue-issue-1')).last, const Offset(-600, 0), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(issueService._issues.first.status, 'done');
      },
    );
  });

  group('Batch 7 - Global Quick Capture FAB', () {
    testWidgets(
      'DashboardScreen displays prominent Capture FAB and opens GlobalCreateIssueSheet',
      (tester) async {
        SharedPreferences.setMockInitialValues({'github_username': 'FrancisGiann'});

        final project1 = Project(
          id: 'proj-1',
          ownerId: 'u1',
          name: 'Mobile App',
          tags: const ['flutter'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final project2 = Project(
          id: 'proj-2',
          ownerId: 'u1',
          name: 'Web Platform',
          tags: const ['react'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final issueService = _MockIssueService([]);
        final stats = DashboardStats(
          projectCount: 2,
          totalIssues: 0,
          openIssues: 0,
          completedIssues: 0,
          byStatus: const {'todo': 0, 'in_progress': 0, 'done': 0},
          byType: const {'task': 0, 'bug': 0},
          byPriority: const {'low': 0, 'medium': 0, 'high': 0},
          projects: [
            ProjectSummary(id: 'proj-1', name: 'Mobile App', total: 0, open: 0, completed: 0),
            ProjectSummary(id: 'proj-2', name: 'Web Platform', total: 0, open: 0, completed: 0),
          ],
        );

        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authUserIdProvider.overrideWith((ref) => 'u1'),
              dashboardStatsProvider.overrideWith((ref) => stats),
              projectServiceProvider
                  .overrideWith((ref) => _MockProjectService([project1, project2])),
              issueServiceProvider.overrideWith((ref) => issueService),
              dashboardServiceProvider.overrideWith((ref) => _MockDashboardService(stats)),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const DashboardScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // 1. Verify FAB is present with + icon and "Capture" label
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Capture'), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsWidgets);

        // 2. Tap FAB to open GlobalCreateIssueSheet
        await tester.tap(find.text('Capture'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 3. Verify GlobalCreateIssueSheet is displayed
        expect(find.byType(GlobalCreateIssueSheet), findsOneWidget);
        expect(find.text('Quick Capture'), findsOneWidget);
        expect(find.text('Project'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Capture issue'), findsOneWidget);

        // 4. Fill in issue title and submit
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'),
          'New Global Captured Task',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Submit form
        await tester.tap(find.text('Capture issue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify issue was created in issueService
        expect(issueService._issues.length, 1);
        expect(issueService._issues.first.title, 'New Global Captured Task');
        expect(issueService._issues.first.projectId, 'proj-1');

        // Verify sheet was dismissed
        expect(find.byType(GlobalCreateIssueSheet), findsNothing);
      },
    );
  });

  group('Batch 7 - Bespoke GitHub Contribution Graph', () {
    test('HTML parser correctly extracts total count and 53x7 days', () {
      const sampleHtml = '''
<div class="js-yearly-contributions">
  <h2 class="f4 text-normal mb-2">
    558
    contributions
    in the last year
  </h2>
  <table class="ContributionCalendar-grid">
    <tbody>
      <tr>
        <td data-date="2025-09-14" id="contribution-day-component-0-0" data-level="1" class="ContributionCalendar-day"></td>
        <td data-date="2025-09-21" id="contribution-day-component-0-1" data-level="0" class="ContributionCalendar-day"></td>
        <td data-date="2025-09-28" id="contribution-day-component-0-2" data-level="2" class="ContributionCalendar-day"></td>
        <td data-date="2025-10-05" id="contribution-day-component-0-3" data-level="3" class="ContributionCalendar-day"></td>
        <td data-date="2025-10-12" id="contribution-day-component-0-4" data-level="4" class="ContributionCalendar-day"></td>
      </tr>
      <tr>
        <td data-date="2025-09-15" id="contribution-day-component-1-0" data-level="4" class="ContributionCalendar-day"></td>
      </tr>
    </tbody>
  </table>
</div>
''';

      final data = GithubContributionsData.parseHtml(sampleHtml);
      expect(data.totalContributions, 558);
      expect(data.days.length, 6);
      expect(data.dateToLevel['2025-09-14'], 1);
      expect(data.dateToLevel['2025-09-21'], 0);
      expect(data.dateToLevel['2025-09-28'], 2);
      expect(data.dateToLevel['2025-10-05'], 3);
      expect(data.dateToLevel['2025-10-12'], 4);
      expect(data.days.first.row, 0);
      expect(data.days.first.col, 0);
    });

    testWidgets('shows input field when username is not set in SharedPreferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: GithubContributionGraph(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('G I T H U B'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
      'renders GitHub Contribution Graph with cyan levels and subtitle when username and data are provided',
      (tester) async {
        SharedPreferences.setMockInitialValues({'github_username': 'FrancisGiann'});

        final mockDays = List.generate(
          53 * 7,
          (index) {
            final col = index ~/ 7;
            final row = index % 7;
            final level = (col + row) % 5;
            return ContributionDay(
              date: '2025-09-14',
              level: level,
              row: row,
              col: col,
            );
          },
        );

        final mockData = GithubContributionsData(
          totalContributions: 558,
          days: mockDays,
          dateToLevel: {'2025-09-14': 1},
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: GithubContributionGraph(
                initialUsername: 'FrancisGiann',
                initialData: mockData,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify Header
        expect(find.text('G I T H U B'), findsOneWidget);
        expect(find.text('Activity'), findsOneWidget);
        expect(
          find.text('Live contribution graph from @FrancisGiann'),
          findsOneWidget,
        );

        // 2. Verify Footer
        expect(find.text('558 contributions in the last year'), findsOneWidget);
        expect(find.text('Less'), findsOneWidget);
        expect(find.text('More'), findsOneWidget);

        // 3. Verify weekday labels
        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Wed'), findsOneWidget);
        expect(find.text('Fri'), findsOneWidget);

        // 4. Verify Theme color levels constants
        expect(
          GithubContributionGraph.level0,
          AppTheme.darkTheme.colorScheme.surfaceContainerHighest,
        );
        expect(
          GithubContributionGraph.level1,
          AppTheme.darkTheme.colorScheme.primary.withValues(alpha: 0.3),
        );
        expect(
          GithubContributionGraph.level2,
          AppTheme.darkTheme.colorScheme.primary.withValues(alpha: 0.5),
        );
        expect(
          GithubContributionGraph.level3,
          AppTheme.darkTheme.colorScheme.primary.withValues(alpha: 0.8),
        );
        expect(
          GithubContributionGraph.level4,
          AppTheme.darkTheme.colorScheme.primary,
        );
      },
    );
  });
}
