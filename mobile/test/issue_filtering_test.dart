import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/issue.dart';
import 'package:mobile/services/issue_service.dart';
import 'package:mobile/utils/issue_filtering.dart';

Issue _issue(
  String id,
  String title,
  String type,
  String priority,
  String status,
  DateTime createdAt,
) => Issue(
  id: id,
  projectId: 'p1',
  title: title,
  type: type,
  priority: priority,
  status: status,
  createdAt: createdAt,
  updatedAt: createdAt,
);

void main() {
  final issues = [
    _issue('1', 'Fix cache', 'bug', 'high', 'todo', DateTime(2026, 1, 2)),
    _issue('2', 'Ship docs', 'task', 'low', 'done', DateTime(2026, 1, 3)),
    _issue(
      '3',
      'Add tests',
      'task',
      'medium',
      'in_progress',
      DateTime(2026, 1, 1),
    ),
  ];

  test('filters by exact enum and sorts without mutating source', () {
    final filtered = filterAndSortIssues(
      issues,
      const IssueFilters(status: 'all', type: 'task', sort: 'priority'),
    );
    expect(filtered.map((issue) => issue.id), ['3', '2']);
    expect(issues.first.id, '1');
  });

  test('priority order matches the Postgres enum descending order', () {
    final sorted = filterAndSortIssues(
      issues,
      const IssueFilters(status: 'all', sort: 'priority'),
    );
    expect(sorted.map((issue) => issue.priority), ['high', 'medium', 'low']);
  });

  test(
    'merges issue pages in server order and retains page filters upstream',
    () {
      final first = IssuePage(
        items: [issues[0], issues[1]],
        total: 3,
        page: 1,
        pageSize: 2,
        pageCount: 2,
      );
      final second = IssuePage(
        items: [issues[1], issues[2]],
        total: 3,
        page: 2,
        pageSize: 2,
        pageCount: 2,
      );
      final merged = mergeIssuePages(first, second);
      expect(merged.items.map((issue) => issue.id), ['1', '2', '3']);
      expect(merged.page, 2);
      expect(merged.pageCount, 2);
    },
  );

  test('pagination errors retain the currently visible page', () {
    final page = IssuePage(
      items: [issues.first],
      total: 6,
      page: 1,
      pageSize: 5,
      pageCount: 2,
    );
    final failed = page.copyWith(paginationError: 'Try again.');
    expect(failed.items.single.id, page.items.single.id);
    expect(failed.paginationError, 'Try again.');
  });
}
