with open('mobile/lib/providers/issues_provider.dart', 'r') as f:
    content = f.read()

target_update = """  Future<void> updateIssue({
    required String issueId,
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
    IssueFilters? filters,
  }) async {
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
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(issueStatusCountsProvider(arg));
    ref.invalidate(activityProvider(arg));
    await refresh(filters: filters);
  }"""

replacement_update = """  Future<void> updateIssue({
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
  }"""

if target_update in content:
    content = content.replace(target_update, replacement_update)
    with open('mobile/lib/providers/issues_provider.dart', 'w') as f:
        f.write(content)
    print("Updated updateIssue in issues_provider.dart")
else:
    print("Could not find updateIssue target")
