import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/activity_log.dart';
import '../../providers/activity_provider.dart';
import '../../services/activity_service.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/makko_card.dart';

class ProjectActivitySection extends ConsumerStatefulWidget {
  final String projectId;
  final bool embeddedInTab;

  const ProjectActivitySection({
    super.key,
    required this.projectId,
    this.embeddedInTab = false,
  });

  @override
  ConsumerState<ProjectActivitySection> createState() =>
      _ProjectActivitySectionState();
}

class _ProjectActivitySectionState
    extends ConsumerState<ProjectActivitySection> {
  ActivityScope _scope = ActivityScope.last30Days;
  final List<ActivityLog> _items = [];
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  int _generation = 0;
  String? _providerSnapshot;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ActivityPage>>(activityProvider(widget.projectId), (
      _,
      next,
    ) {
      final page = next.valueOrNull;
      if (page == null || _scope != ActivityScope.last30Days) return;
      _scheduleProviderPage(page, force: true);
    });
    final initial = ref.watch(activityProvider(widget.projectId));
    if (_scope == ActivityScope.last30Days && initial.hasValue) {
      _scheduleProviderPage(initial.value!);
    }
    if (initial.hasError && _items.isEmpty) {
      return MakkoErrorState(message: 'Unable to load project activity.');
    }
    if (initial.isLoading && _items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Activity',
          subtitle: _scope == ActivityScope.last30Days
              ? 'Last 30 days'
              : 'All time',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Refresh activity',
                onPressed: _loadingMore ? null : _refreshCurrentScope,
                icon: const Icon(Icons.refresh_rounded),
              ),
              PopupMenuButton<ActivityScope>(
                tooltip: 'Activity scope',
                initialValue: _scope,
                onSelected: _changeScope,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: ActivityScope.last30Days,
                    child: Text('Last 30 days'),
                  ),
                  PopupMenuItem(
                    value: ActivityScope.allTime,
                    child: Text('All time'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_items.isEmpty)
          const EmptyState(
            icon: Icons.timeline_outlined,
            title: 'No activity yet',
            subtitle: 'Project and issue changes will appear here.',
          )
        else if (widget.embeddedInTab)
          MakkoCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _items.length; i++)
                  _TimelineActivityRow(
                    log: _items[i],
                    isFirst: i == 0,
                    isLast:
                        i == _items.length - 1 && !_loadingMore && !_hasMore,
                  ),
                if (_loadingMore)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_loadingMore && _hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _loadMore,
                        child: const Text('Load more activity'),
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          MakkoCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SizedBox(
              height: _activityViewportHeight(context),
              child: ListView.builder(
                primary: false,
                physics: const ClampingScrollPhysics(),
                itemCount: _items.length + (_loadingMore || _hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _items.length) {
                    return _TimelineActivityRow(
                      log: _items[index],
                      isFirst: index == 0,
                      isLast: index == _items.length - 1 &&
                          !_loadingMore &&
                          !_hasMore,
                    );
                  }
                  if (_loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: OutlinedButton(
                      onPressed: _loadMore,
                      child: const Text('Load more activity'),
                    ),
                  );
                },
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Could not load more activity. Try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Future<void> _changeScope(ActivityScope scope) async {
    if (scope == _scope) return;
    final generation = ++_generation;
    setState(() {
      _scope = scope;
      _items.clear();
      _loadingMore = false;
      _page = 1;
      _hasMore = false;
      _error = null;
      _providerSnapshot = null;
    });
    try {
      final page = await ref
          .read(activityServiceProvider)
          .getActivityLogs(widget.projectId, scope: scope);
      if (mounted && generation == _generation && _scope == scope) {
        setState(() {
          _items
            ..clear()
            ..addAll(page.items);
          _hasMore = page.hasMore;
          _page = page.page;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation && _scope == scope) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _refreshCurrentScope() async {
    final generation = ++_generation;
    final scope = _scope;
    setState(() {
      _loadingMore = true;
      _error = null;
      if (scope == ActivityScope.last30Days) _providerSnapshot = null;
    });
    try {
      final page = await ref
          .read(activityServiceProvider)
          .getActivityLogs(widget.projectId, scope: scope);
      if (mounted && generation == _generation && _scope == scope) {
        setState(() {
          _items
            ..clear()
            ..addAll(page.items);
          _hasMore = page.hasMore;
          _page = page.page;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation && _scope == scope) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted && generation == _generation && _scope == scope) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final generation = _generation;
    final scope = _scope;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(activityServiceProvider)
          .getActivityLogs(widget.projectId, page: _page + 1, scope: _scope);
      if (mounted && generation == _generation && _scope == scope) {
        setState(() {
          final merged = mergeActivityItems(_items, page.items);
          _items
            ..clear()
            ..addAll(merged);
          _hasMore = page.hasMore;
          _page = page.page;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation && _scope == scope) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted && generation == _generation && _scope == scope) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _replaceFirstPage(ActivityPage page) {
    if (page.page != 1) return;
    setState(() {
      _items
        ..clear()
        ..addAll(page.items);
      _hasMore = page.hasMore;
      _page = page.page;
      _error = null;
    });
  }

  void _scheduleProviderPage(ActivityPage page, {bool force = false}) {
    final snapshot = page.items
        .map(
          (item) =>
              '${item.id}:${item.type}:${item.description}:${item.createdAt.microsecondsSinceEpoch}',
        )
        .join('|');
    if (!force && _providerSnapshot == snapshot) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scope != ActivityScope.last30Days) return;
      if (_providerSnapshot == snapshot) return;
      _providerSnapshot = snapshot;
      _replaceFirstPage(page);
    });
  }

  double _activityViewportHeight(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return math.min(440, math.max(300, 5 * 70 * textScale));
  }
}

class _TimelineActivityRow extends StatelessWidget {
  final ActivityLog log;
  final bool isFirst;
  final bool isLast;

  const _TimelineActivityRow({
    required this.log,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _actionColor(context, log.type);
    final icon = _actionIcon(log.type);
    final lineColor = scheme.primary.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? 13 : 0,
                  bottom: isLast ? 13 : 0,
                  child: Container(
                    width: 2,
                    color: lineColor,
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _relative(log.createdAt),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _actionIcon(String type) {
  if (type.contains('create') || type.contains('add')) {
    return Icons.add_rounded;
  }
  if (type.contains('delete') || type.contains('remove')) {
    return Icons.delete_outline_rounded;
  }
  if (type.contains('update') || type.contains('edit')) {
    return Icons.edit_outlined;
  }
  return Icons.info_outline_rounded;
}

Color _actionColor(BuildContext context, String type) {
  if (type.contains('delete') || type.contains('remove')) {
    return context.makkoSemantics.bug;
  }
  if (type.contains('update') || type.contains('edit')) {
    return context.makkoSemantics.medium;
  }
  return context.makkoSemantics.inProgress;
}

String _relative(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}
