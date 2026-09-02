import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/dashboard_service.dart';
import '../models/dashboard_stats.dart';
import 'auth_provider.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) async {
  final service = ref.watch(dashboardServiceProvider);
  final ownerId = ref.watch(authUserIdProvider);
  if (ownerId == null) return emptyDashboardStats();
  return service.getStats(ownerId: ownerId);
});
