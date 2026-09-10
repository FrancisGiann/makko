import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../services/project_service.dart';
import 'activity_provider.dart';
import 'auth_provider.dart';
import 'dashboard_provider.dart';

final projectServiceProvider = Provider((ref) => ProjectService());

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  int _requestGeneration = 0;
  String? _activeUserId;

  @override
  Future<List<Project>> build() async {
    // Rebuild the notifier for every auth transition; never retain one user's
    // project list while another session is active.
    final userId = ref.watch(authUserIdProvider);
    if (_activeUserId != userId) {
      // Token refreshes can emit auth events for the same user; only identity
      // changes invalidate in-flight requests and cached project state.
      _activeUserId = userId;
      _requestGeneration++;
    }
    final generation = _requestGeneration;
    if (userId == null) return [];
    final projects = await _fetchProjects(userId);
    if (generation != _requestGeneration ||
        ref.read(authUserIdProvider) != userId) {
      return [];
    }
    return projects;
  }

  Future<List<Project>> _fetchProjects(String userId) {
    return ref.read(projectServiceProvider).listProjects(userId);
  }

  Future<void> refresh() async {
    final userId = ref.read(authUserIdProvider);
    final generation = ++_requestGeneration;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final projects = await _fetchProjects(userId);
      if (generation == _requestGeneration &&
          ref.read(authUserIdProvider) == userId) {
        state = AsyncValue.data(projects);
      }
    } catch (error, stack) {
      if (generation == _requestGeneration &&
          ref.read(authUserIdProvider) == userId) {
        state = AsyncValue.error(error, stack);
      }
    }
  }

  Future<void> createProject({
    required String name,
    String? description,
    List<String>? tags,
  }) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');
    final generation = _requestGeneration;

    final newProject = await ref
        .read(projectServiceProvider)
        .createProject(
          userId,
          name: name,
          description: description,
          tags: tags,
        );

    // Optimistic update or refresh
    if (_isCurrent(userId, generation)) {
      final currentList = state.value ?? [];
      state = AsyncValue.data([newProject, ...currentList]);
      ref.invalidate(dashboardStatsProvider);
    }
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
    final generation = _requestGeneration;
    final updated = await ref
        .read(projectServiceProvider)
        .updateProject(
          userId,
          projectId,
          name: name,
          description: description,
          tags: tags,
        );
    if (_isCurrent(userId, generation)) {
      state = AsyncValue.data([
        for (final project in state.value ?? <Project>[])
          if (project.id == projectId) updated else project,
      ]);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(activityProvider(projectId));
    }
  }

  Future<void> deleteProject(String projectId) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null)
      throw Exception('You are signed out. Please sign in again.');
    final generation = _requestGeneration;
    await ref.read(projectServiceProvider).deleteProject(userId, projectId);
    if (_isCurrent(userId, generation)) {
      state = AsyncValue.data(
        (state.value ?? <Project>[])
            .where((project) => project.id != projectId)
            .toList(),
      );
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(activityProvider(projectId));
    }
  }

  bool _isCurrent(String userId, int generation) {
    return generation == _requestGeneration &&
        ref.read(authUserIdProvider) == userId;
  }
}

final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
  () {
    return ProjectsNotifier();
  },
);
