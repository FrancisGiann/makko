import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/projects_provider.dart';
import '../../models/project.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/makko_logo.dart';
import '../../widgets/makko_card.dart';
import '../../widgets/makko_search_delegate.dart';
import '../../widgets/refresh_error_banner.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/tag_chip.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final dashboardAsync = ref.watch(dashboardStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    Future<void> refreshProjects() async {
      await ref.read(projectsProvider.notifier).refresh();
      try {
        await ref.refresh(dashboardStatsProvider.future).then<void>((_) {});
      } catch (_) {
        // Project content is already retained and remains usable offline.
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const MakkoLogo(compact: true),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => showSearch(
              context: context,
              delegate: MakkoSearchDelegate(ref),
            ),
          ),
          IconButton(
            tooltip: 'Account and settings',
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/projects/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New project'),
      ),
      body: projectsAsync.when(
        skipLoadingOnRefresh: true,
        skipError: true,
        loading: () => const _ProjectsLoadingSkeleton(),
        error: (error, _) => MakkoErrorState(
          message: _friendlyProjectError(error),
          onRetry: () => unawaited(refreshProjects()),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No projects yet',
              subtitle: 'Give your next build a calm, focused home.',
              actionButton: FilledButton.icon(
                onPressed: () => context.push('/projects/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create project'),
              ),
            );
          }
          final summaries = dashboardAsync.valueOrNull?.projects ?? const [];
          return RefreshIndicator(
            onRefresh: refreshProjects,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              children: [
                if (projectsAsync.hasError)
                  RefreshErrorBanner(
                    message: 'Could not refresh projects. Showing the last loaded list.',
                    onRetry: refreshProjects,
                  ),
                Text(
                  'Projects',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${projects.length} ${projects.length == 1 ? 'workspace' : 'workspaces'} in motion',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                ...projects.asMap().entries.map((entry) {
                  final project = entry.value;
                  final summary = summaries
                      .where((item) => item.id == project.id)
                      .toList();
                  final counts = summary.isEmpty ? null : summary.first;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProjectCard(
                      project: project,
                      openCount: counts?.open ?? 0,
                      completedCount: counts?.completed ?? 0,
                      totalCount: counts?.total ?? 0,
                      onTap: () => context.push('/projects/${project.id}'),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProjectsLoadingSkeleton extends StatelessWidget {
  const _ProjectsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerContainer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          const ShimmerBox(width: 140, height: 32),
          const SizedBox(height: 8),
          const ShimmerBox(width: 200, height: 16),
          const SizedBox(height: 20),
          for (int i = 0; i < 4; i++) ...[
            MakkoCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.all(
                      Radius.circular(MakkoShapes.radius),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 160, height: 20),
                        SizedBox(height: 8),
                        ShimmerBox(width: double.infinity, height: 14),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            ShimmerBox(width: 68, height: 22),
                            SizedBox(width: 8),
                            ShimmerBox(width: 68, height: 22),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final int openCount;
  final int completedCount;
  final int totalCount;
  final VoidCallback onTap;
  const _ProjectCard({
    required this.project,
    required this.openCount,
    required this.completedCount,
    required this.totalCount,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.makkoSemantics;
    return Semantics(
      button: true,
      label: 'Open project ${project.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
        onTap: onTap,
        child: MakkoCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder_open_rounded,
                      color: scheme.onPrimaryContainer,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (project.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 3),
                          Text(
                            project.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (project.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.tags
                      .take(3)
                      .map<Widget>((tag) => TagChip(tag: tag))
                      .toList(),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _CountPill(label: '$openCount open', color: scheme.primary),
                  _CountPill(
                    label: '$completedCount done',
                    color: semantics.done,
                  ),
                  if (totalCount > 0)
                    Text(
                      '$totalCount total',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CountPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MakkoShapes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _friendlyProjectError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty || text.contains('Instance of')
      ? 'Check your connection and try again.'
      : text;
}
