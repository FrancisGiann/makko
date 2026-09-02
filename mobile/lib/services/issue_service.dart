import '../core/supabase/supabase_client.dart';
import '../models/issue.dart';
import 'validation.dart';

class IssuePage {
  final List<Issue> items;
  final int total;
  final int page;
  final int pageSize;
  final int pageCount;

  IssuePage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pageCount,
  });

  factory IssuePage.empty() {
    return IssuePage(
      items: const [],
      total: 0,
      page: 1,
      pageSize: IssueService.pageSize,
      pageCount: 0,
    );
  }
}

/// Combines adjacent server pages while keeping the server's order and
/// removing duplicate ids from retries or overlapping ranges.
IssuePage mergeIssuePages(IssuePage current, IssuePage next) {
  final byId = <String, Issue>{
    for (final issue in current.items) issue.id: issue,
  };
  for (final issue in next.items) {
    byId[issue.id] = issue;
  }
  final merged = <Issue>[];
  final seen = <String>{};
  for (final issue in [...current.items, ...next.items]) {
    if (seen.add(issue.id)) merged.add(byId[issue.id]!);
  }
  return IssuePage(
    items: merged,
    total: next.total,
    page: next.page,
    pageSize: next.pageSize,
    pageCount: next.pageCount,
  );
}

class IssueLookup {
  final String projectId;
  final String issueId;

  const IssueLookup({required this.projectId, required this.issueId});

  @override
  bool operator ==(Object other) =>
      other is IssueLookup &&
      other.projectId == projectId &&
      other.issueId == issueId;

  @override
  int get hashCode => Object.hash(projectId, issueId);
}

class IssueFilters {
  final String status;
  final String type;
  final String priority;
  final String sort;

  const IssueFilters({
    this.status = 'all',
    this.type = 'all',
    this.priority = 'all',
    this.sort = 'newest',
  });
}

class IssueService {
  static const _issueColumns =
      'id,project_id,title,description,type,priority,status,created_at,updated_at';
  static const pageSize = 5;

  Future<Map<String, int>> statusCounts(String projectId) async {
    final project = Validation.requireId(projectId, 'Project');
    final results = await Future.wait([
      supabase
          .from('issues')
          .select('id')
          .eq('project_id', project)
          .eq('status', 'todo')
          .count(),
      supabase
          .from('issues')
          .select('id')
          .eq('project_id', project)
          .eq('status', 'in_progress')
          .count(),
      supabase
          .from('issues')
          .select('id')
          .eq('project_id', project)
          .eq('status', 'done')
          .count(),
    ]);
    return {
      'todo': results[0].count,
      'in_progress': results[1].count,
      'done': results[2].count,
    };
  }

  Future<IssuePage> listIssues(
    String projectId, {
    int page = 1,
    IssueFilters filters = const IssueFilters(),
  }) async {
    final project = Validation.requireId(projectId, 'Project');
    if (page < 1 || page > 10000)
      throw const ValidationError('Issue page is invalid.');
    if (!const [
          'all',
          'todo',
          'in_progress',
          'done',
        ].contains(filters.status) ||
        !const ['all', 'task', 'bug'].contains(filters.type) ||
        !const ['all', 'low', 'medium', 'high'].contains(filters.priority) ||
        !const [
          'newest',
          'oldest',
          'updated',
          'title',
          'priority',
        ].contains(filters.sort)) {
      throw const ValidationError('Issue filters are invalid.');
    }
    var query = supabase
        .from('issues')
        .select(_issueColumns)
        .eq('project_id', project);

    if (filters.status != 'all') {
      query = query.eq('status', filters.status);
    }
    if (filters.type != 'all') {
      query = query.eq('type', filters.type);
    }
    if (filters.priority != 'all') {
      query = query.eq('priority', filters.priority);
    }

    dynamic orderQuery = query;

    switch (filters.sort) {
      case 'oldest':
        orderQuery = orderQuery
            .order('created_at', ascending: true)
            .order('title', ascending: true)
            .order('id', ascending: true);
        break;
      case 'updated':
        orderQuery = orderQuery
            .order('updated_at', ascending: false)
            .order('title', ascending: true)
            .order('id', ascending: true);
        break;
      case 'title':
        orderQuery = orderQuery
            .order('title', ascending: true)
            .order('id', ascending: true);
        break;
      case 'priority':
        // The Postgres issue_priority enum is declared low, medium, high;
        // descending enum order therefore returns high, medium, low.
        orderQuery = orderQuery
            .order('priority', ascending: false)
            .order('title', ascending: true)
            .order('id', ascending: true);
        break;
      case 'newest':
      default:
        orderQuery = orderQuery
            .order('created_at', ascending: false)
            .order('title', ascending: true)
            .order('id', ascending: false);
        break;
    }

    final response = await orderQuery.range(
      (page - 1) * pageSize,
      page * pageSize - 1,
    );

    final items = (response as List)
        .map((json) => Issue.fromJson(json))
        .toList();
    var countQuery = supabase
        .from('issues')
        .select('id')
        .eq('project_id', project);
    if (filters.status != 'all')
      countQuery = countQuery.eq('status', filters.status);
    if (filters.type != 'all') countQuery = countQuery.eq('type', filters.type);
    if (filters.priority != 'all')
      countQuery = countQuery.eq('priority', filters.priority);
    final totalResponse = await countQuery.count();
    final total = totalResponse.count;

    return IssuePage(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize,
      pageCount: total == 0 ? 0 : (total / pageSize).ceil(),
    );
  }

  Future<Issue?> getIssue(String projectId, String issueId) async {
    final project = Validation.requireId(projectId, 'Project');
    final issue = Validation.requireId(issueId, 'Issue');
    final response = await supabase
        .from('issues')
        .select(_issueColumns)
        .eq('project_id', project)
        .eq('id', issue)
        .maybeSingle();
    return response == null ? null : Issue.fromJson(response);
  }

  Future<Issue> createIssue(
    String projectId, {
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
  }) async {
    final project = Validation.requireId(projectId, 'Project');
    final normalized = Validation.normalizeIssue(
      title: title,
      description: description,
      type: type,
      priority: priority,
      status: status,
    );
    final response = await supabase
        .from('issues')
        .insert({
          'project_id': project,
          'title': normalized.title,
          'description': normalized.description,
          'type': normalized.type,
          'priority': normalized.priority,
          'status': normalized.status,
        })
        .select(_issueColumns)
        .single();

    return Issue.fromJson(response);
  }

  Future<Issue> updateIssue(
    String projectId,
    String issueId, {
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
  }) async {
    final project = Validation.requireId(projectId, 'Project');
    final issue = Validation.requireId(issueId, 'Issue');
    final normalized = Validation.normalizeIssue(
      title: title,
      description: description,
      type: type,
      priority: priority,
      status: status,
    );
    final response = await supabase
        .from('issues')
        .update({
          'title': normalized.title,
          'description': normalized.description,
          'type': normalized.type,
          'priority': normalized.priority,
          'status': normalized.status,
        })
        .eq('id', issue)
        .eq('project_id', project)
        .select(_issueColumns)
        .single();

    return Issue.fromJson(response);
  }

  Future<void> deleteIssue(String projectId, String issueId) async {
    final project = Validation.requireId(projectId, 'Project');
    final issue = Validation.requireId(issueId, 'Issue');
    await supabase
        .from('issues')
        .delete()
        .eq('id', issue)
        .eq('project_id', project);
  }
}
