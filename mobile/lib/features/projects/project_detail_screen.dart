import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/issue.dart';
import '../../models/project.dart';
import '../../providers/issues_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/github_provider.dart';
import '../../services/issue_service.dart';
import '../../widgets/app_section_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectsProvider);
    final issuesAsync = ref.watch(issuesProvider(widget.projectId));
    final countsAsync = ref.watch(issueStatusCountsProvider(widget.projectId));
    if (projectAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final project = projectAsync.valueOrNull
        ?.where((item) => item.id == widget.projectId)
        .toList();
    if (projectAsync.hasError)
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: MakkoErrorState(
          message: 'Unable to load this project.',
          onRetry: () => ref.read(projectsProvider.notifier).refresh(),
        ),
      );
    if (project == null || project.isEmpty) {
      if (projectAsync.isLoading)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(issuesProvider(widget.projectId).notifier)
              .refresh(filters: _filters);
          ref.invalidate(issueStatusCountsProvider(widget.projectId));
          ref.invalidate(githubProvider(widget.projectId));
          ref.invalidate(activityProvider(widget.projectId));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
          children: [
            _ProjectMeta(project: item),
            const SizedBox(height: 20),
            _StatusSummary(
              counts:
                  countsAsync.valueOrNull ??
                  const {'todo': 0, 'in_progress': 0, 'done': 0},
            ),
            const SizedBox(height: 22),
            AppSectionHeader(title: 'Internal issues', subtitle: _filtersLabel),
            const SizedBox(height: 10),
            _FilterBar(filters: _filters, onTap: _showFilters),
            const SizedBox(height: 12),
            _IssueList(
              projectId: widget.projectId,
              issuesAsync: issuesAsync,
              onLoadMore: () => ref
                  .read(issuesProvider(widget.projectId).notifier)
                  .loadMore(),
              onEdit: (issue) => context.push(
                '/projects/${widget.projectId}/issues/${issue.id}/edit',
              ),
              onDelete: _confirmDeleteIssue,
              onStatusChange: _setStatus,
            ),
            const SizedBox(height: 24),
            GithubSection(projectId: widget.projectId),
            const SizedBox(height: 24),
            ProjectActivitySection(projectId: widget.projectId),
          ],
        ),
      ),
    );
  }

  String get _filtersLabel {
    final active = <String>[];
    if (_filters.status != 'all') active.add(_statusLabel(_filters.status));
    if (_filters.type != 'all')
      active.add(_filters.type == 'bug' ? 'Bugs' : 'Tasks');
    if (_filters.priority != 'all')
      active.add(
        '${_filters.priority[0].toUpperCase()}${_filters.priority.substring(1)} priority',
      );
    return active.isEmpty ? 'All internal work' : active.join(' · ');
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<IssueFilters>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _FiltersSheet(initial: _filters),
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    await ref
        .read(issuesProvider(widget.projectId).notifier)
        .refresh(filters: result);
  }

  Future<void> _setStatus(Issue issue, String status) async {
    if (_busy || issue.status == status) return;
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as ${_statusLabel(status)}')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update issue status. Try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteIssue(Issue issue) async {
    final confirmed =
        await showDialog<bool>(
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
                onPressed: () => context.pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(issuesProvider(widget.projectId).notifier)
          .deleteIssue(issue.id, filters: _filters);
      ref.invalidate(issueStatusCountsProvider(widget.projectId));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete this issue. Try again.'),
          ),
        );
    }
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirmed =
        await showDialog<bool>(
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
                onPressed: () => context.pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    try {
      await ref.read(projectsProvider.notifier).deleteProject(project.id);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete this project. Try again.'),
          ),
        );
    }
  }
}

class _ProjectMeta extends StatelessWidget {
  final Project project;
  const _ProjectMeta({required this.project});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat('MMM d, yyyy');
    return MakkoCard(
      borderRadius: MakkoShapes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.description?.isNotEmpty == true
                ? project.description!
                : 'No description yet.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: project.description?.isNotEmpty == true
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
          if (project.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.tags.map((tag) => TagChip(tag: tag)).toList(),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Created ${date.format(project.createdAt)}  ·  Updated ${date.format(project.updatedAt)}',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  final Map<String, int> counts;
  const _StatusSummary({required this.counts});
  @override
  Widget build(BuildContext context) {
    final semantics = context.makkoSemantics;
    final rows = [
      ('To do', counts['todo'] ?? 0, semantics.todo),
      ('In progress', counts['in_progress'] ?? 0, semantics.inProgress),
      ('Done', counts['done'] ?? 0, semantics.done),
    ];
    return MakkoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Issue status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: rows[i].$3,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rows[i].$1,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '${rows[i].$2}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final IssueFilters filters;
  final VoidCallback onTap;
  const _FilterBar({required this.filters, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.tune_rounded),
    label: Text(_filterSummary(filters)),
    style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
  );
}

class _IssueList extends StatelessWidget {
  final String projectId;
  final AsyncValue<IssuePage> issuesAsync;
  final VoidCallback onLoadMore;
  final ValueChanged<Issue> onEdit;
  final ValueChanged<Issue> onDelete;
  final void Function(Issue, String) onStatusChange;
  const _IssueList({
    required this.projectId,
    required this.issuesAsync,
    required this.onLoadMore,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });
  @override
  Widget build(BuildContext context) => issuesAsync.when(
    skipLoadingOnRefresh: false,
    loading: () => const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (error, _) =>
        MakkoErrorState(message: 'Unable to load internal issues. Try again.'),
    data: (page) {
      if (page.items.isEmpty)
        return const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No issues here',
          subtitle: 'Adjust the filters or capture the next piece of work.',
        );
      return Column(
        children: [
          for (final issue in page.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IssueCard(
                issue: issue,
                onEdit: () => onEdit(issue),
                onDelete: () => onDelete(issue),
                onStatusChange: (status) => onStatusChange(issue, status),
              ),
            ),
          if (page.pageCount > page.page)
            Column(
              children: [
                Text(
                  'Showing ${page.items.length} of ${page.total}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        ],
      );
    },
  );
}

class _IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChange;
  const _IssueCard({
    required this.issue,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typeColor = issue.type == 'bug'
        ? context.makkoSemantics.bug
        : context.makkoSemantics.task;
    return MakkoCard(
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
                  if (value.startsWith('status:'))
                    onStatusChange(value.substring(7));
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
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
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          if (issue.description?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(left: 31, top: 6),
              child: Text(
                issue.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusChip(status: issue.status),
              PriorityChip(priority: issue.priority),
            ],
          ),
        ],
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final IssueFilters initial;
  const _FiltersSheet({required this.initial});
  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late IssueFilters _filters = widget.initial;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter and sort',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            _filterGroup(
              'Status',
              {
                'all': 'All statuses',
                'todo': 'To do',
                'in_progress': 'In progress',
                'done': 'Done',
              },
              _filters.status,
              (value) => setState(
                () => _filters = IssueFilters(
                  status: value,
                  type: _filters.type,
                  priority: _filters.priority,
                  sort: _filters.sort,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _filterGroup(
              'Type',
              {'all': 'All types', 'task': 'Tasks', 'bug': 'Bugs'},
              _filters.type,
              (value) => setState(
                () => _filters = IssueFilters(
                  status: _filters.status,
                  type: value,
                  priority: _filters.priority,
                  sort: _filters.sort,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _filterGroup(
              'Priority',
              {
                'all': 'All priorities',
                'high': 'High',
                'medium': 'Medium',
                'low': 'Low',
              },
              _filters.priority,
              (value) => setState(
                () => _filters = IssueFilters(
                  status: _filters.status,
                  type: _filters.type,
                  priority: value,
                  sort: _filters.sort,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _filterGroup(
              'Sort',
              {
                'newest': 'Newest',
                'oldest': 'Oldest',
                'updated': 'Recently updated',
                'title': 'Title',
                'priority': 'Priority',
              },
              _filters.sort,
              (value) => setState(
                () => _filters = IssueFilters(
                  status: _filters.status,
                  type: _filters.type,
                  priority: _filters.priority,
                  sort: value,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_filters),
              child: const Text('Apply filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterGroup(
    String label,
    Map<String, String> options,
    String value,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map(
          (item) => DropdownMenuItem(value: item.key, child: Text(item.value)),
        )
        .toList(),
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}

String _filterSummary(IssueFilters filters) {
  final count = [
    filters.status != 'all',
    filters.type != 'all',
    filters.priority != 'all',
  ].where((active) => active).length;
  return count == 0
      ? 'Filter and sort issues'
      : '$count filter${count == 1 ? '' : 's'} active · ${filters.sort == 'newest' ? 'Newest first' : filters.sort}';
}

String _statusLabel(String status) => switch (status) {
  'in_progress' => 'In progress',
  'done' => 'Done',
  _ => 'To do',
};
