import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../services/project_service.dart';
import 'activity_provider.dart';
import 'auth_provider.dart';
import 'dashboard_provider.dart';

final projectServiceProvider = Provider((ref) => ProjectService());

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    // Rebuild the notifier for every auth transition; never retain one user's
    // project list while another session is active.
    ref.watch(authProvider);
    final userId = ref.watch(authUserIdProvider);
    if (userId == null) return [];
    return _fetchProjects();
  }

  Future<List<Project>> _fetchProjects() async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return [];
    return ref.read(projectServiceProvider).listProjects(userId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProjects());
  }

  Future<void> createProject({
    required String name,
    String? description,
    List<String>? tags,
  }) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    final newProject = await ref
        .read(projectServiceProvider)
        .createProject(
          userId,
          name: name,
          description: description,
          tags: tags,
        );

    // Optimistic update or refresh
    if (ref.read(authUserIdProvider) == userId) {
      final currentList = state.value ?? [];
      state = AsyncValue.data([newProject, ...currentList]);
    }
    ref.invalidate(dashboardStatsProvider);
  }

  Future<void> updateProject(
    String projectId, {
    required String name,
    String? description,
    List<String>? tags,
  }) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null)
      throw Exception('You are signed out. Please sign in again.');
    final updated = await ref
        .read(projectServiceProvider)
        .updateProject(
          userId,
          projectId,
          name: name,
          description: description,
          tags: tags,
        );
    if (ref.read(authUserIdProvider) == userId) {
      state = AsyncValue.data([
        for (final project in state.value ?? <Project>[])
          if (project.id == projectId) updated else project,
      ]);
    }
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(activityProvider(projectId));
  }

  Future<void> deleteProject(String projectId) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null)
      throw Exception('You are signed out. Please sign in again.');
    await ref.read(projectServiceProvider).deleteProject(userId, projectId);
    if (ref.read(authUserIdProvider) == userId) {
      state = AsyncValue.data(
        (state.value ?? <Project>[])
            .where((project) => project.id != projectId)
            .toList(),
      );
    }
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(activityProvider(projectId));
  }
}

final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
  () {
    return ProjectsNotifier();
  },
);
