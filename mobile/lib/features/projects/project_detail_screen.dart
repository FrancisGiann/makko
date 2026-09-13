import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/issue.dart';
import '../../models/project.dart';
import '../../providers/activity_provider.dart';
import '../../providers/github_provider.dart';
import '../../providers/issues_provider.dart';
import '../../providers/projects_provider.dart';
import '../../services/issue_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/makko_card.dart';
import '../../widgets/priority_chip.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/tag_chip.dart';
import '../github/github_section.dart';
import 'project_activity_section.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});
  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  IssueFilters _filters = const IssueFilters();
  bool _busy = false;

  void _updateFilter({
    String? status,
    String? type,
    String? priority,
    String? sort,
  }) {
    final next = IssueFilters(
      status: status ?? _filters.status,
      type: type ?? _filters.type,
      priority: priority ?? _filters.priority,
      sort: sort ?? _filters.sort,
    );
    setState(() => _filters = next);
    ref.read(issuesProvider(widget.projectId).notifier).refresh(filters: next);
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectsProvider);
    final issuesAsync = ref.watch(issuesProvider(widget.projectId));
    final countsAsync = ref.watch(issueStatusCountsProvider(widget.projectId));
    final scheme = Theme.of(context).colorScheme;

    if (projectAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final project = projectAsync.valueOrNull
        ?.where((item) => item.id == widget.projectId)
        .toList();
    if (projectAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: MakkoErrorState(
          message: 'Unable to load this project.',
          onRetry: () => ref.read(projectsProvider.notifier).refresh(),
        ),
      );
    }
    if (project == null || project.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const EmptyState(
          icon: Icons.folder_off_outlined,
          title: 'Project not found',
          subtitle:
              'It may have been deleted or you may no longer have access.',
        ),
      );
    }

    final item = project.first;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Project Details'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Edit project',
              onPressed: () => context.push('/projects/${item.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Project actions',
              onSelected: (value) {
                if (value == 'delete') _confirmDeleteProject(item);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete project'),
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/projects/${item.id}/issues/new'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New issue'),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: _CompactProjectMetaCard(
                    project: item,
                    counts: countsAsync.valueOrNull ??
                        const {'todo': 0, 'in_progress': 0, 'done': 0},
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    indicatorColor: scheme.primary,
                    indicatorWeight: 3,
                    labelColor: scheme.primary,
                    unselectedLabelColor: scheme.onSurfaceVariant,
                    labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Issues'),
                      Tab(text: 'GitHub'),
                      Tab(text: 'Activity'),
                    ],
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
                  // Tab 1: Issues
                  _IssuesTab(
                    projectId: widget.projectId,
                    filters: _filters,
                    issuesAsync: issuesAsync,
                    onFilterChanged: _updateFilter,
                    onLoadMore: () => ref
                        .read(issuesProvider(widget.projectId).notifier)
                        .loadMore(),
                    onRefresh: () async {
                      await ref
                          .read(issuesProvider(widget.projectId).notifier)
                          .refresh(filters: _filters);
                      ref.invalidate(
                        issueStatusCountsProvider(widget.projectId),
                      );
                    },
                    onEdit: (issue) => context.push(
                      '/projects/${widget.projectId}/issues/${issue.id}/edit',
                    ),
                    onDelete: _confirmDeleteIssue,
                    onStatusChange: _setStatus,
                  ),
                  // Tab 2: GitHub
                  RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(githubProvider(widget.projectId)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      child: GithubSection(projectId: widget.projectId),
                    ),
                  ),
                  // Tab 3: Activity
                  RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(activityProvider(widget.projectId)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      child: ProjectActivitySection(
                        projectId: widget.projectId,
                        embeddedInTab: true,
                      ),
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }

  Future<void> _setStatus(Issue issue, String status) async {
    if (_busy || issue.status == status) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    try {
      await ref
          .read(issuesProvider(widget.projectId).notifier)
          .updateIssue(
            issueId: issue.id,
            title: issue.title,
            description: issue.description,
            type: issue.type,
            priority: issue.priority,
            status: status,
            filters: _filters,
          );
      ref.invalidate(issueStatusCountsProvider(widget.projectId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as ${_statusLabel(status)}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update issue status. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteIssue(Issue issue) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete issue?'),
        content: Text('“${issue.title}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => context.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(issuesProvider(widget.projectId).notifier)
          .deleteIssue(issue.id, filters: _filters);
      ref.invalidate(issueStatusCountsProvider(widget.projectId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete this issue. Try again.'),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
          '“${project.name}” and its internal issues will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => context.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(projectsProvider.notifier).deleteProject(project.id);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete this project. Try again.'),
          ),
        );
      }
    }
  }
}

class _CompactProjectMetaCard extends StatelessWidget {
  final Project project;
  final Map<String, int> counts;

  const _CompactProjectMetaCard({
    required this.project,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.makkoSemantics;

    final hasDescription = project.description?.trim().isNotEmpty == true;
    final hasTags = project.tags.isNotEmpty;

    return MakkoCard(
      padding: const EdgeInsets.all(20),
      borderRadius: MakkoShapes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            project.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          if (hasDescription) ...[
            const SizedBox(height: 8),
            Text(
              project.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (hasTags) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.tags.map((tag) => TagChip(tag: tag)).toList(),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Status summary counts with colored dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusDotCount(
                label: 'To do',
                count: counts['todo'] ?? 0,
                color: semantics.todo,
              ),
              _StatusDotCount(
                label: 'In progress',
                count: counts['in_progress'] ?? 0,
                color: scheme.primary,
              ),
              _StatusDotCount(
                label: 'Done',
                count: counts['done'] ?? 0,
                color: semantics.done,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDotCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusDotCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _IssuesTab extends StatelessWidget {
  final String projectId;
  final IssueFilters filters;
  final AsyncValue<IssuePage> issuesAsync;
  final void Function({
    String? status,
    String? type,
    String? priority,
    String? sort,
  }) onFilterChanged;
  final VoidCallback onLoadMore;
  final RefreshCallback onRefresh;
  final ValueChanged<Issue> onEdit;
  final ValueChanged<Issue> onDelete;
  final void Function(Issue, String) onStatusChange;

  const _IssuesTab({
    required this.projectId,
    required this.filters,
    required this.issuesAsync,
    required this.onFilterChanged,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Scrollable Filter Chips Row
        _HorizontalFilterBar(
          filters: filters,
          onFilterChanged: onFilterChanged,
        ),
        // Issues List
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: issuesAsync.when(
              skipLoadingOnRefresh: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => const MakkoErrorState(
                message: 'Unable to load internal issues. Try again.',
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No issues here',
                        subtitle:
                            'Adjust the filters or capture the next piece of work.',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: page.items.length +
                      (page.pageCount > page.page ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < page.items.length) {
                      final issue = page.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _IssueCard(
                            key: ValueKey('${issue.id}-${issue.status}-${issue.updatedAt}'),
                            issue: issue,
                            onEdit: () => onEdit(issue),
                            onDelete: () => onDelete(issue),
                            onStatusChange: (status) =>
                                onStatusChange(issue, status),
                          ),
                        ),
                      );
                    }

                    // Pagination footer
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          if (page.paginationError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      page.paginationError!,
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: onLoadMore,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            'Showing ${page.items.length} of ${page.total}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: onLoadMore,
                              child: const Text('Load more issues'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HorizontalFilterBar extends StatelessWidget {
  final IssueFilters filters;
  final void Function({
    String? status,
    String? type,
    String? priority,
    String? sort,
  }) onFilterChanged;

  const _HorizontalFilterBar({
    required this.filters,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Status Chips
          ChoiceChip(
            label: const Text('Open'),
            selected: filters.status == 'open',
            onSelected: (selected) {
              if (selected) onFilterChanged(status: 'open');
            },
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('All'),
            selected: filters.status == 'all',
            onSelected: (selected) {
              if (selected) onFilterChanged(status: 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Todo'),
            selected: filters.status == 'todo',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'todo' : 'open');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('In Progress'),
            selected: filters.status == 'in_progress',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'in_progress' : 'open');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Done'),
            selected: filters.status == 'done',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'done' : 'open');
            },
          ),

          // Divider
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: scheme.outlineVariant),
          const SizedBox(width: 8),

          // Type Chips
          ChoiceChip(
            label: const Text('All types'),
            selected: filters.type == 'all',
            onSelected: (selected) {
              if (selected) onFilterChanged(type: 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Task'),
            selected: filters.type == 'task',
            onSelected: (selected) {
              onFilterChanged(type: selected ? 'task' : 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Bug'),
            selected: filters.type == 'bug',
            onSelected: (selected) {
              onFilterChanged(type: selected ? 'bug' : 'all');
            },
          ),

          // Divider
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: scheme.outlineVariant),
          const SizedBox(width: 8),

          // Priority Chips
          ChoiceChip(
            label: const Text('All priority'),
            selected: filters.priority == 'all',
            onSelected: (selected) {
              if (selected) onFilterChanged(priority: 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('High'),
            selected: filters.priority == 'high',
            onSelected: (selected) {
              onFilterChanged(priority: selected ? 'high' : 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Medium'),
            selected: filters.priority == 'medium',
            onSelected: (selected) {
              onFilterChanged(priority: selected ? 'medium' : 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Low'),
            selected: filters.priority == 'low',
            onSelected: (selected) {
              onFilterChanged(priority: selected ? 'low' : 'all');
            },
          ),

          // Divider
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: scheme.outlineVariant),
          const SizedBox(width: 8),

          // Sort Dropdown Menu
          PopupMenuButton<String>(
            tooltip: 'Sort issues',
            initialValue: filters.sort,
            onSelected: (val) => onFilterChanged(sort: val),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MakkoShapes.radiusFull),
                border: Border.all(color: scheme.outlineVariant),
                color: scheme.surfaceContainerHigh,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortLabel(filters.sort),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest')),
              PopupMenuItem(
                value: 'updated',
                child: Text('Recently updated'),
              ),
              PopupMenuItem(value: 'title', child: Text('Title')),
              PopupMenuItem(value: 'priority', child: Text('Priority')),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChange;

  const _IssueCard({
    super.key,
    required this.issue,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.makkoSemantics;
    final typeColor = issue.type == 'bug' ? semantics.bug : semantics.task;

    return Dismissible(
      key: Key('issue-${issue.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: semantics.done,
          borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Mark done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right: Mark as done with confirmation
          if (issue.status == 'done') return false;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Mark as done?'),
              content: Text('Mark “${issue.title}” as completed?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: semantics.done,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Mark done'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            onStatusChange('done');
          }
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left: Delete with confirmation dialog
          onDelete();
          return false;
        }
        return false;
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
          onTap: onEdit,
          child: MakkoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      issue.type == 'bug'
                          ? Icons.bug_report_outlined
                          : Icons.checklist_rounded,
                      color: typeColor,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        issue.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 48),
                      tooltip: 'Issue actions',
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                        if (value.startsWith('status:')) {
                          onStatusChange(value.substring(7));
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'status:todo',
                          child: Text(
                            issue.status == 'todo' ? 'To do  ✓' : 'Mark to do',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status:in_progress',
                          child: Text(
                            issue.status == 'in_progress'
                                ? 'In progress  ✓'
                                : 'Mark in progress',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status:done',
                          child: Text(
                            issue.status == 'done' ? 'Done  ✓' : 'Mark done',
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (issue.description?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(left: 31, top: 4),
                    child: Text(
                      issue.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Tappable status chip that cycles through statuses
                    Tooltip(
                      message: 'Tap to change status',
                      child: Material(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(MakkoShapes.radiusFull),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(MakkoShapes.radiusFull),
                          onTap: () {
                            final next = switch (issue.status) {
                              'todo' => 'in_progress',
                              'in_progress' => 'done',
                              _ => 'todo',
                            };
                            onStatusChange(next);
                          },
                          child: StatusChip(status: issue.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    PriorityChip(priority: issue.priority),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _sortLabel(String sort) => switch (sort) {
      'oldest' => 'Oldest',
      'updated' => 'Recently updated',
      'title' => 'Title',
      'priority' => 'Priority',
      _ => 'Newest',
    };

String _statusLabel(String status) => switch (status) {
      'in_progress' => 'In progress',
      'done' => 'Done',
      _ => 'To do',
    };


class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
