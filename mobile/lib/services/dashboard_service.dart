import 'package:flutter/foundation.dart';

import '../core/supabase/supabase_client.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  Future<DashboardStats> getStats({String? ownerId}) async {
    try {
      var projectsQuery = supabase.from('projects').select('id, name');
      if (ownerId != null && ownerId.trim().isNotEmpty)
        projectsQuery = projectsQuery.eq('owner_id', ownerId.trim());
      final projects = await projectsQuery;
      final issues = await supabase
          .from('issues')
          .select('project_id, type, priority, status');
      return calculateDashboardStats(
        List<Map<String, dynamic>>.from(projects),
        List<Map<String, dynamic>>.from(issues),
      );
    } catch (error, stack) {
      debugPrint('DashboardService.getStats error: $error');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }
}

DashboardStats emptyDashboardStats() => DashboardStats(
  projectCount: 0,
  totalIssues: 0,
  openIssues: 0,
  completedIssues: 0,
  byStatus: const {'todo': 0, 'in_progress': 0, 'done': 0},
  byType: const {'task': 0, 'bug': 0},
  byPriority: const {'high': 0, 'medium': 0, 'low': 0},
  projects: const [],
);

DashboardStats calculateDashboardStats(
  List<Map<String, dynamic>> projects,
  List<Map<String, dynamic>> issues,
) {
  final byStatus = <String, int>{'todo': 0, 'in_progress': 0, 'done': 0};
  final byType = <String, int>{'task': 0, 'bug': 0};
  final byPriority = <String, int>{'high': 0, 'medium': 0, 'low': 0};
  final projectIssues = <String, Map<String, int>>{};

  for (final issue in issues) {
    final status = issue['status'] as String? ?? 'todo';
    final type = issue['type'] as String? ?? 'task';
    final priority = issue['priority'] as String? ?? 'medium';
    final projectId = issue['project_id'] as String? ?? '';
    if (byStatus.containsKey(status)) byStatus[status] = byStatus[status]! + 1;
    if (byType.containsKey(type)) byType[type] = byType[type]! + 1;
    if (byPriority.containsKey(priority))
      byPriority[priority] = byPriority[priority]! + 1;
    final counts = projectIssues.putIfAbsent(
      projectId,
      () => {'open': 0, 'completed': 0, 'total': 0},
    );
    counts['total'] = counts['total']! + 1;
    counts[status == 'done' ? 'completed' : 'open'] =
        counts[status == 'done' ? 'completed' : 'open']! + 1;
  }

  final summaries =
      projects.map((project) {
        final id = project['id'] as String? ?? '';
        final counts =
            projectIssues[id] ?? {'open': 0, 'completed': 0, 'total': 0};
        return ProjectSummary(
          id: id,
          name: project['name'] as String? ?? 'Untitled project',
          total: counts['total']!,
          open: counts['open']!,
          completed: counts['completed']!,
        );
      }).toList()..sort((a, b) {
        final openComparison = b.open.compareTo(a.open);
        if (openComparison != 0) return openComparison;
        final nameComparison = a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        );
        return nameComparison != 0 ? nameComparison : a.id.compareTo(b.id);
      });

  return DashboardStats(
    projectCount: projects.length,
    totalIssues: issues.length,
    openIssues: (byStatus['todo'] ?? 0) + (byStatus['in_progress'] ?? 0),
    completedIssues: byStatus['done'] ?? 0,
    byStatus: byStatus,
    byType: byType,
    byPriority: byPriority,
    projects: summaries,
  );
}
