import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/error_state.dart';
import '../../widgets/makko_card.dart';
import '../../widgets/makko_logo.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String get _displayName {
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = user?.userMetadata?['first_name'];
    if (firstName is String && firstName.trim().isNotEmpty)
      return firstName.trim();
    final email = user?.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Builder';
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    return hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
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
      body: statsAsync.when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => MakkoErrorState(
          message: _friendlyDashboardError(error),
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardStatsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                '$_greeting, $_displayName',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 5),
              Text(
                'A clear view of your current build queue.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _CompanionCard(stats: stats),
              const SizedBox(height: 20),
              const AppSectionHeader(title: 'Workspace at a glance'),
              const SizedBox(height: 10),
              _MetricList(stats: stats),
              const SizedBox(height: 22),
              _StatusCard(stats: stats),
              if (stats.projects.isNotEmpty) ...[
                const SizedBox(height: 22),
                _WorkloadCard(stats: stats),
              ],
              const SizedBox(height: 22),
              _QuickActions(
                onProjects: () => context.go('/projects'),
                onNewProject: () => context.push('/projects/new'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  final DashboardStats stats;
  const _CompanionCard({required this.stats});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = stats.totalIssues == 0
        ? 'Your board is ready for its first signal.'
        : stats.openIssues == 0
        ? 'Everything is complete. Take a breath, then choose what is next.'
        : '${stats.openIssues} open ${stats.openIssues == 1 ? 'issue' : 'issues'} across ${stats.projectCount} ${stats.projectCount == 1 ? 'project' : 'projects'}.';
    return MakkoCard(
      borderRadius: MakkoShapes.radiusXl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(MakkoShapes.radius),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/makko-pet.png',
              semanticLabel: 'Makko mascot',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Makko pulse',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: 5),
                Text(message, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricList extends StatelessWidget {
  final DashboardStats stats;
  const _MetricList({required this.stats});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = [
      (
        Icons.folder_outlined,
        '${stats.projectCount}',
        'Projects',
        'Your active project spaces',
        scheme.primary,
      ),
      (
        Icons.pending_actions_rounded,
        '${stats.openIssues}',
        'Open issues',
        'To do and in progress',
        context.makkoSemantics.inProgress,
      ),
      (
        Icons.task_alt_rounded,
        '${stats.completedIssues}',
        'Completed',
        'Done internal issues',
        context.makkoSemantics.done,
      ),
      (
        Icons.view_list_rounded,
        '${stats.totalIssues}',
        'Total issues',
        'Internal Makko issues only',
        scheme.onSurface,
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < metrics.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == metrics.length - 1 ? 0 : 10),
            child: _MetricTile(
              icon: metrics[i].$1,
              value: metrics[i].$2,
              label: metrics[i].$3,
              detail: metrics[i].$4,
              accent: metrics[i].$5,
            ),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String detail;
  final Color accent;
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    required this.accent,
  });
  @override
  Widget build(BuildContext context) => MakkoCard(
    child: Row(
      children: [
        Icon(icon, color: accent, size: 24),
        const SizedBox(width: 14),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusCard extends StatelessWidget {
  final DashboardStats stats;
  const _StatusCard({required this.stats});
  @override
  Widget build(BuildContext context) {
    final semantics = context.makkoSemantics;
    final rows = [
      ('To do', stats.byStatus['todo'] ?? 0, semantics.todo),
      ('In progress', stats.byStatus['in_progress'] ?? 0, semantics.inProgress),
      ('Done', stats.byStatus['done'] ?? 0, semantics.done),
    ];
    return MakkoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Issue status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: row.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.$1,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${row.$2}',
                    style: Theme.of(context).textTheme.labelLarge,
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

class _WorkloadCard extends StatelessWidget {
  final DashboardStats stats;
  const _WorkloadCard({required this.stats});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MakkoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project workload',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...stats.projects
              .take(6)
              .map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${project.open} open',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${project.completed} done',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: context.makkoSemantics.done),
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

class _QuickActions extends StatelessWidget {
  final VoidCallback onProjects;
  final VoidCallback onNewProject;
  const _QuickActions({required this.onProjects, required this.onNewProject});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onProjects,
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('View projects'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: FilledButton.icon(
          onPressed: onNewProject,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New project'),
        ),
      ),
    ],
  );
}

String _friendlyDashboardError(Object error) {
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  return message.isEmpty || message.contains('Instance of')
      ? 'Check your connection and try again.'
      : message;
}
