import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../services/activity_service.dart';
import 'auth_provider.dart';

final activityServiceProvider = Provider((ref) => ActivityService());

final activityProvider = FutureProvider.autoDispose
    .family<ActivityPage, String>((ref, projectId) async {
      if (ref.watch(authUserIdProvider) == null) {
        return ActivityPage(
          items: const [],
          page: 1,
          pageSize: ActivityService.pageSize,
          hasMore: false,
        );
      }
      final service = ref.watch(activityServiceProvider);
      return service.getActivityLogs(projectId);
    });

final recentActivitiesProvider =
    FutureProvider.autoDispose<List<ActivityLog>>((ref) async {
      if (ref.watch(authUserIdProvider) == null) return const [];
      final service = ref.watch(activityServiceProvider);
      return service.getRecentActivities(lookbackDays: 30);
    });
