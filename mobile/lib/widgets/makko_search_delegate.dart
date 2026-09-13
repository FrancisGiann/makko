import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../providers/issues_provider.dart';
import '../providers/projects_provider.dart';
import 'empty_state.dart';
import 'makko_card.dart';
import 'priority_chip.dart';
import 'status_chip.dart';
import 'tag_chip.dart';

class MakkoSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef ref;

  MakkoSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search projects and issues…';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear query',
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
      const SizedBox(width: 4),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildContent(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildContent(context);
  }

  void _navigateTo(BuildContext context, String route) {
    final router = GoRouter.of(context);
    close(context, route);
    router.push(route);
  }

  Widget _buildContent(BuildContext context) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return _buildInitialState(context);
    }

    return Consumer(
      builder: (context, ref, _) {
        final scheme = Theme.of(context).colorScheme;
        final semantics = context.makkoSemantics;

        final projects = ref.watch(projectsProvider).valueOrNull ?? const [];
        final dashboardStats = ref.watch(dashboardStatsProvider).valueOrNull;
        final issuesAsync = ref.watch(searchIssuesProvider(cleanQuery));

        final q = cleanQuery.toLowerCase();
        final matchedProjects = projects.where((p) {
          final nameMatch = p.name.toLowerCase().contains(q);
          final descMatch = (p.description ?? '').toLowerCase().contains(q);
          final tagMatch = p.tags.any((t) => t.toLowerCase().contains(q));
          return nameMatch || descMatch || tagMatch;
        }).toList();

        final projectMap = {for (final p in projects) p.id: p};
        final summaryMap = {
          for (final s in dashboardStats?.projects ?? []) s.id: s,
        };

        final matchedIssues = issuesAsync.valueOrNull ?? const [];
        final isLoading = issuesAsync.isLoading && matchedProjects.isEmpty;

        if (isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (matchedProjects.isEmpty && matchedIssues.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results found',
            subtitle: 'No projects or issues match “$cleanQuery”.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (matchedProjects.isNotEmpty) ...[
              _SectionTitle(title: 'Projects (${matchedProjects.length})'),
              const SizedBox(height: 8),
              ...matchedProjects.map((project) {
                final summary = summaryMap[project.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MakkoCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: MakkoShapes.radius,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MakkoShapes.radius),
                      onTap: () => _navigateTo(context, '/projects/${project.id}'),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                MakkoShapes.radiusSm,
                              ),
                            ),
                            child: Icon(
                              Icons.folder_outlined,
                              color: scheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (project.description?.isNotEmpty == true) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    project.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                                if (project.tags.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: project.tags
                                        .take(3)
                                        .map((t) => TagChip(tag: t))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (summary != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${summary.open} open',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (matchedIssues.isNotEmpty) ...[
              _SectionTitle(title: 'Issues (${matchedIssues.length})'),
              const SizedBox(height: 8),
              ...matchedIssues.map((issue) {
                final project = projectMap[issue.projectId];
                final isBug = issue.type == 'bug';
                final typeColor = isBug ? semantics.bug : semantics.task;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MakkoCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: MakkoShapes.radius,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MakkoShapes.radius),
                      onTap: () => _navigateTo(
                        context,
                        '/projects/${issue.projectId}/issues/${issue.id}/edit',
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                MakkoShapes.radiusSm,
                              ),
                            ),
                            child: Icon(
                              isBug
                                  ? Icons.bug_report_outlined
                                  : Icons.checklist_rounded,
                              color: typeColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  issue.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${project?.name ?? 'Project'} • ${issue.type}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusChip(status: issue.status),
                              const SizedBox(height: 4),
                              PriorityChip(priority: issue.priority),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInitialState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Search Makko',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Search across your projects, tags, and internal issues.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
    );
  }
}
