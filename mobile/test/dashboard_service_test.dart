import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/dashboard_service.dart';

void main() {
  test(
    'dashboard aggregation counts only internal issue rows and sorts workload',
    () {
      final stats = calculateDashboardStats(
        [
          {'id': 'p1', 'name': 'Alpha'},
          {'id': 'p2', 'name': 'Beta'},
        ],
        [
          {
            'project_id': 'p1',
            'type': 'task',
            'priority': 'high',
            'status': 'todo',
          },
          {
            'project_id': 'p1',
            'type': 'bug',
            'priority': 'medium',
            'status': 'done',
          },
          {
            'project_id': 'p2',
            'type': 'task',
            'priority': 'low',
            'status': 'in_progress',
          },
        ],
      );

      expect(stats.projectCount, 2);
      expect(stats.totalIssues, 3);
      expect(stats.openIssues, 2);
      expect(stats.completedIssues, 1);
      expect(stats.byType, {'task': 2, 'bug': 1});
      expect(stats.projects.first.id, 'p1');
      expect(stats.projects.first.open, 1);
    },
  );
}
