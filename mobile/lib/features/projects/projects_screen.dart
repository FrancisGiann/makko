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
import '../../widgets/tag_chip.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final dashboardAsync = ref.watch(dashboardStatsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const MakkoLogo(compact: true),
        actions: [
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
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => MakkoErrorState(
          message: _friendlyProjectError(error),
          onRetry: () => ref.read(projectsProvider.notifier).refresh(),
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
            onRefresh: () async {
              await ref.read(projectsProvider.notifier).refresh();
              ref.invalidate(dashboardStatsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              children: [
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
                ...projects.map((project) {
                  final summary = summaries
                      .where((item) => item.id == project.id)
                      .toList();
                  final counts = summary.isEmpty ? null : summary.first;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProjectCard(
                      project: project,
                      openCount: counts?.open ?? 0,
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

class _ProjectCard extends StatelessWidget {
  final Project project;
  final int openCount;
  final int totalCount;
  final VoidCallback onTap;
  const _ProjectCard({
    required this.project,
    required this.openCount,
    required this.totalCount,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Open project ${project.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
        onTap: onTap,
        child: MakkoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(MakkoShapes.radius),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (project.description != null &&
                        project.description!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        project.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (project.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: project.tags
                            .take(4)
                            .map<Widget>((tag) => TagChip(tag: tag))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.radio_button_checked_rounded,
                          size: 15,
                          color: context.makkoSemantics.inProgress,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$openCount open',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
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
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
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
