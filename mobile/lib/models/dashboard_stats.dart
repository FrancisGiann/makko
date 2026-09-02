class DashboardStats {
  final int projectCount;
  final int totalIssues;
  final int openIssues;
  final int completedIssues;
  final Map<String, int> byStatus;
  final Map<String, int> byType;
  final Map<String, int> byPriority;
  final List<ProjectSummary> projects;

  DashboardStats({
    required this.projectCount,
    required this.totalIssues,
    required this.openIssues,
    required this.completedIssues,
    required this.byStatus,
    required this.byType,
    required this.byPriority,
    required this.projects,
  });
}

class ProjectSummary {
  final String id;
  final String name;
  final int total;
  final int open;
  final int completed;

  ProjectSummary({
    required this.id,
    required this.name,
    required this.total,
    required this.open,
    required this.completed,
  });
}
