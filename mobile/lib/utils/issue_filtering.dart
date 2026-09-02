import '../models/issue.dart';
import '../services/issue_service.dart';

List<Issue> filterAndSortIssues(List<Issue> issues, IssueFilters filters) {
  // This helper is for local lists/tests only. Paginated production reads use
  // IssueService's Postgres ordering so pages cannot be reordered client-side.
  final filtered = issues
      .where(
        (issue) =>
            (filters.status == 'all' || issue.status == filters.status) &&
            (filters.type == 'all' || issue.type == filters.type) &&
            (filters.priority == 'all' || issue.priority == filters.priority),
      )
      .toList();
  filtered.sort((left, right) {
    final comparison = switch (filters.sort) {
      'oldest' => left.createdAt.compareTo(right.createdAt),
      'updated' => right.updatedAt.compareTo(left.updatedAt),
      'title' => left.title.toLowerCase().compareTo(right.title.toLowerCase()),
      'priority' =>
        _priorityRank(right.priority) - _priorityRank(left.priority),
      _ => right.createdAt.compareTo(left.createdAt),
    };
    if (comparison != 0) return comparison;
    final titleComparison = left.title.toLowerCase().compareTo(
      right.title.toLowerCase(),
    );
    return titleComparison != 0 ? titleComparison : left.id.compareTo(right.id);
  });
  return filtered;
}

int _priorityRank(String priority) => switch (priority) {
  'high' => 3,
  'medium' => 2,
  _ => 1,
};
