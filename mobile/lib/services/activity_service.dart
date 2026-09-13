import '../core/supabase/supabase_client.dart';
import '../models/activity_log.dart';
import 'validation.dart';

class ActivityPage {
  final List<ActivityLog> items;
  final int page;
  final int pageSize;
  final bool hasMore;

  ActivityPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}

List<ActivityLog> mergeActivityItems(
  List<ActivityLog> current,
  List<ActivityLog> next,
) {
  final merged = <ActivityLog>[];
  final seen = <String>{};
  for (final item in [...current, ...next]) {
    if (seen.add(item.id)) merged.add(item);
  }
  return merged;
}

class ActivityService {
  static const int pageSize = 30;
  static const int lookbackDays = 30;

  Future<ActivityPage> getActivityLogs(
    String projectId, {
    int page = 1,
    ActivityScope scope = ActivityScope.last30Days,
  }) async {
    final project = Validation.requireId(projectId, 'Project');
    if (page < 1 || page > 10000)
      throw const ValidationError('Activity page is invalid.');
    var query = supabase
        .from('activity_log')
        .select('id,project_id,issue_id,action,description,created_at')
        .eq('project_id', project)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(
          (page - 1) * pageSize,
          page * pageSize,
        ); // Request one extra for hasMore
    if (scope == ActivityScope.last30Days) {
      final cutoff = DateTime.now()
          .subtract(const Duration(days: lookbackDays))
          .toIso8601String();
      query = supabase
          .from('activity_log')
          .select('id,project_id,issue_id,action,description,created_at')
          .eq('project_id', project)
          .gte('created_at', cutoff)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range((page - 1) * pageSize, page * pageSize);
    }

    final response = await query;
    final rows = (response as List)
        .map((json) => ActivityLog.fromJson(json))
        .toList();

    return ActivityPage(
      items: rows.take(pageSize).toList(),
      page: page,
      pageSize: pageSize,
      hasMore: rows.length > pageSize,
    );
  }

  Future<List<ActivityLog>> getRecentActivities({int lookbackDays = 30}) async {
    try {
      final cutoff = DateTime.now()
          .subtract(Duration(days: lookbackDays))
          .toIso8601String();
      final response = await supabase
          .from('activity_log')
          .select('id,project_id,issue_id,action,description,created_at')
          .gte('created_at', cutoff)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => ActivityLog.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

enum ActivityScope { last30Days, allTime }
