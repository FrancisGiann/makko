import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/projects/create_issue_sheet.dart';
import 'package:mobile/features/projects/create_project_sheet.dart';
import 'package:mobile/features/projects/project_activity_section.dart';
import 'package:mobile/features/projects/project_detail_screen.dart';
import 'package:mobile/models/activity_log.dart';
import 'package:mobile/models/issue.dart';
import 'package:mobile/models/project.dart';
import 'package:mobile/providers/activity_provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/github_provider.dart';
import 'package:mobile/providers/issues_provider.dart';
import 'package:mobile/providers/projects_provider.dart';
import 'package:mobile/services/activity_service.dart';
import 'package:mobile/services/github_service.dart';
import 'package:mobile/services/issue_service.dart';
import 'package:mobile/services/project_service.dart';

class _MockProjectService extends ProjectService {
  final List<Project> projects;
  _MockProjectService(this.projects);

  @override
  Future<List<Project>> listProjects(String ownerId) async => projects;
}

class _MockIssueService extends IssueService {
  final IssuePage issuePage;
  _MockIssueService(this.issuePage);

  @override
  Future<IssuePage> listIssues(
    String projectId, {
    int page = 1,
    IssueFilters filters = const IssueFilters(),
  }) async => issuePage;

  @override
  Future<Map<String, int>> statusCounts(String projectId) async => {
    'todo': 1,
    'in_progress': 0,
    'done': 0,
  };
}

void main() {
  group('CreateIssueSheet SegmentedButtons', () {
    testWidgets('renders Type, Priority, and Status as SegmentedButtons', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CreateIssueSheet(projectId: 'p1'),
          ),
        ),
      );

      // 3 SegmentedButton widgets (Type, Priority, Status)
      expect(find.byType(SegmentedButton<String>), findsNWidgets(3));
      expect(find.text('Task'), findsOneWidget);
      expect(find.text('Bug'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('To do'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap 'Bug' segment
      await tester.tap(find.text('Bug'));
      await tester.pump();
      final typeSegmentedButton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>).first,
      );
      expect(typeSegmentedButton.selected, {'bug'});
    });
  });

  group('CreateProjectSheet TagInput and PopScope', () {
    testWidgets('adds and removes tag chips interactively', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CreateProjectSheet(),
          ),
        ),
      );

      // Find the tag text field
      final tagField = find.widgetWithText(TextFormField, 'Add tag');
      expect(tagField, findsOneWidget);

      // Enter a tag and submit
      await tester.enterText(tagField, 'flutter');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.byType(InputChip), findsOneWidget);
      expect(find.text('flutter'), findsOneWidget);

      // Add another tag via suffix icon
      await tester.enterText(tagField, 'mobile');
      await tester.tap(find.byTooltip('Add tag'));
      await tester.pump();

      expect(find.byType(InputChip), findsNWidgets(2));
      expect(find.text('mobile'), findsOneWidget);

      // Delete the first tag chip
      final deleteButtons = find.descendant(
        of: find.byType(InputChip),
        matching: find.byIcon(Icons.clear),
      );
      await tester.tap(deleteButtons.first);
      await tester.pump();

      expect(find.byType(InputChip), findsOneWidget);
      expect(find.text('mobile'), findsOneWidget);
    });
  });

  group('ProjectActivitySection embedded in tab', () {
    testWidgets('renders timeline rail without inner ListView when embeddedInTab is true', (
      tester,
    ) async {
      final logs = [
        ActivityLog(
          id: '1',
          projectId: 'p1',
          type: 'issue_create',
          description: 'Created issue Fix login',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        ActivityLog(
          id: '2',
          projectId: 'p1',
          type: 'issue_update',
          description: 'Updated issue Fix login',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityProvider('p1').overrideWith(
              (ref) async => ActivityPage(
                items: logs,
                page: 1,
                pageSize: 20,
                hasMore: false,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: ProjectActivitySection(
                  projectId: 'p1',
                  embeddedInTab: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Created issue Fix login'), findsOneWidget);
      expect(find.text('Updated issue Fix login'), findsOneWidget);

      // Verify timeline icons are rendered
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });
  });

  group('ProjectDetailScreen Tabbed UX', () {
    testWidgets('renders pinned metadata card, TabBar, and horizontal filter chips', (
      tester,
    ) async {
      final project = Project(
        id: 'p1',
        ownerId: 'u1',
        name: 'Makko Engine',
        description: 'Core processing service for Makko',
        tags: const ['core', 'dart'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final issues = [
        Issue(
          id: 'i1',
          projectId: 'p1',
          title: 'Implement database sync',
          description: 'Sync postgres models',
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

      // Pinned compact metadata
      expect(find.text('Core processing service for Makko'), findsOneWidget);
      expect(find.text('core'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);

      // TabBar tabs
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);

      // Horizontal Filter Chips & Status Summary
      expect(find.text('All status'), findsOneWidget);
      expect(find.text('To do'), findsOneWidget); // Status summary in meta card
      expect(find.text('Todo'), findsOneWidget); // Filter chip
      expect(find.text('In progress'), findsOneWidget); // Status summary in meta card
      expect(find.text('In Progress'), findsOneWidget); // Filter chip
      expect(find.text('Done'), findsNWidgets(2)); // Status summary & chip
      expect(find.text('Task'), findsOneWidget); // Chip
      expect(find.text('Bug'), findsOneWidget); // Chip
      expect(find.text('High'), findsOneWidget); // Chip
      expect(find.text('TODO'), findsOneWidget); // Issue status chip

      // Dismissible Issue Card
      expect(find.byType(Dismissible), findsOneWidget);
      expect(find.text('Implement database sync'), findsOneWidget);

      // Switch to Activity Tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Last 30 days'), findsOneWidget);
    });
  });
}
