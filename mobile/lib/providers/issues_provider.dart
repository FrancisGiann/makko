import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_provider.dart';
import 'auth_provider.dart';
import 'dashboard_provider.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';

final issueServiceProvider = Provider((ref) => IssueService());

class IssuesNotifier extends FamilyAsyncNotifier<IssuePage, String> {
  IssueFilters _filters = const IssueFilters();
  int _requestGeneration = 0;
  bool _loadingMore = false;
  int _loadMoreRequest = 0;
  String? _activeUserId;

  @override
  Future<IssuePage> build(String arg) async {
    final userId = ref.watch(authUserIdProvider);
    if (_activeUserId != userId) {
      _activeUserId = userId;
      _filters = const IssueFilters();
      _requestGeneration++;
      _loadingMore = false;
      _loadMoreRequest++;
    }
    if (userId == null) return IssuePage.empty();
    return _fetchIssues(filters: _filters);
  }

  Future<IssuePage> _fetchIssues({
    int page = 1,
    IssueFilters filters = const IssueFilters(),
  }) async {
    return ref
        .read(issueServiceProvider)
        .listIssues(arg, page: page, filters: filters);
  }

  Future<void> refresh({IssueFilters? filters}) async {
    final selectedFilters = filters ?? _filters;
    _filters = selectedFilters;
    final generation = ++_requestGeneration;
    final previous = state;
    state = const AsyncLoading<IssuePage>().copyWithPrevious(previous);
    try {
      final page = await _fetchIssues(filters: selectedFilters);
      if (generation == _requestGeneration) state = AsyncValue.data(page);
    } catch (error, stack) {
      if (generation == _requestGeneration) {
        state = AsyncError<IssuePage>(error, stack).copyWithPrevious(previous);
      }
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (_loadingMore || current == null || current.page >= current.pageCount) {
      return;
    }
    final generation = _requestGeneration;
    final request = ++_loadMoreRequest;
    _loadingMore = true;
    state = AsyncValue.data(current.copyWith(paginationError: null));
    try {
      final next = await _fetchIssues(
        page: current.page + 1,
        filters: _filters,
      );
      if (generation == _requestGeneration) {
        state = AsyncValue.data(mergeIssuePages(current, next));
      }
    } catch (_) {
      if (generation == _requestGeneration && request == _loadMoreRequest) {
        state = AsyncValue.data(
          current.copyWith(
            paginationError: 'Unable to load more issues. Try again.',
          ),
        );
      }
    } finally {
      if (request == _loadMoreRequest) _loadingMore = false;
    }
  }

  Future<void> createIssue({
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
  }) async {
    await ref
        .read(issueServiceProvider)
        .createIssue(
          arg,
          title: title,
          description: description,
          type: type,
          priority: priority,
          status: status,
        );
    // Refresh issues list
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(issueStatusCountsProvider(arg));
    ref.invalidate(activityProvider(arg));
    try {
      await refresh();
    } catch (_) {
      // The create succeeded; leave any stale list visible with its refresh
      // error rather than keeping the form open and risking a duplicate issue.
    }
  }

  Future<void> updateIssue({
    required String issueId,
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
    IssueFilters? filters,
  }) async {
    // Optimistic Update
    final current = state.valueOrNull;
    if (current != null) {
      final items = current.items.toList();
      final index = items.indexWhere((i) => i.id == issueId);
      if (index != -1) {
        final existing = items[index];
        final updated = Issue(
          id: existing.id,
          projectId: existing.projectId,
          title: title,
          description: description,
          type: type,
          priority: priority,
          status: status,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        items[index] = updated;

        // Local sort to immediately move "done" tasks to the bottom
        items.sort((a, b) {
          int statusWeight(String s) {
            if (s == 'todo') return 0;
            if (s == 'in_progress') return 1;
            if (s == 'done') return 2;
            return 3;
          }

          final wA = statusWeight(a.status);
          final wB = statusWeight(b.status);
          if (wA != wB) return wA.compareTo(wB);
          return b.updatedAt.compareTo(a.updatedAt);
        });

        state = AsyncValue.data(current.copyWith(items: items));
      }
    }

    try {
      await ref
          .read(issueServiceProvider)
          .updateIssue(
            arg,
            issueId,
            title: title,
            description: description,
            type: type,
            priority: priority,
            status: status,
          );
    } catch (e) {
      // Revert on error by refreshing
      await refresh(filters: filters);
      rethrow;
    }

    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(issueStatusCountsProvider(arg));
    ref.invalidate(activityProvider(arg));

    // Silent refresh (do not set state to loading)
    final selectedFilters = filters ?? _filters;
    _filters = selectedFilters;
    final generation = ++_requestGeneration;
    try {
      final page = await _fetchIssues(filters: selectedFilters);
      if (generation == _requestGeneration) state = AsyncValue.data(page);
    } catch (error, stack) {
      if (generation == _requestGeneration) {
        state = AsyncValue.error(error, stack);
      }
    }
  }

  Future<void> deleteIssue(String issueId, {IssueFilters? filters}) async {
    await ref.read(issueServiceProvider).deleteIssue(arg, issueId);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(issueStatusCountsProvider(arg));
    ref.invalidate(activityProvider(arg));
    try {
      await refresh(filters: filters);
    } catch (_) {
      // The delete already succeeded remotely. A later refresh can recover the
      // list without telling the user the mutation itself failed.
    }
  }
}

final issuesProvider =
    AsyncNotifierProviderFamily<IssuesNotifier, IssuePage, String>(() {
      return IssuesNotifier();
    });

final issueStatusCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, projectId) {
      if (ref.watch(authUserIdProvider) == null) {
        return const {'todo': 0, 'in_progress': 0, 'done': 0};
      }
      return ref.read(issueServiceProvider).statusCounts(projectId);
    });

final issueProvider = FutureProvider.autoDispose.family<Issue?, IssueLookup>((
  ref,
  lookup,
) {
  if (ref.watch(authUserIdProvider) == null) return null;
  return ref
      .read(issueServiceProvider)
      .getIssue(lookup.projectId, lookup.issueId);
});

final searchIssuesProvider = FutureProvider.autoDispose
    .family<List<Issue>, String>((ref, query) async {
      final cleanQuery = query.trim();
      if (cleanQuery.isEmpty) return const [];
      if (ref.watch(authUserIdProvider) == null) return const [];
      return ref.read(issueServiceProvider).searchIssues(cleanQuery);
    });
