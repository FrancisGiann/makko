import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/github_service.dart';
import 'auth_provider.dart';

final githubServiceProvider = Provider((ref) => GithubService());

final githubProvider = FutureProvider.autoDispose
    .family<GithubProjectData, String>((ref, projectId) async {
      if (ref.watch(authUserIdProvider) == null) {
        return GithubProjectData(
          link: null,
          commits: const [],
          issues: const [],
        );
      }
      final service = ref.watch(githubServiceProvider);
      return service.getProjectData(projectId);
    });

class GithubNotifier extends StateNotifier<AsyncValue<void>> {
  final GithubService _service;
  final Ref _ref;

  GithubNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<void> connect(String projectId, String owner, String repo) async {
    state = const AsyncValue.loading();
    try {
      await _service.connect(projectId, owner, repo);
      state = const AsyncValue.data(null);
      _ref.invalidate(githubProvider(projectId));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Error.throwWithStackTrace(e, stack);
    }
  }

  Future<void> syncGithub(String projectId) async {
    state = const AsyncValue.loading();
    try {
      await _service.syncGithub(projectId);
      state = const AsyncValue.data(null);
      _ref.invalidate(githubProvider(projectId));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Error.throwWithStackTrace(e, stack);
    }
  }

  Future<void> disconnect(String projectId, String linkId) async {
    state = const AsyncValue.loading();
    try {
      await _service.disconnect(projectId, linkId);
      state = const AsyncValue.data(null);
      _ref.invalidate(githubProvider(projectId));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Error.throwWithStackTrace(e, stack);
    }
  }
}

final githubNotifierProvider =
    StateNotifierProvider<GithubNotifier, AsyncValue<void>>((ref) {
      return GithubNotifier(ref.watch(githubServiceProvider), ref);
    });
