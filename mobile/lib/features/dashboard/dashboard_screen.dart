import 'dart:async';

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
import '../../widgets/makko_mascot.dart';
import '../../widgets/makko_search_delegate.dart';
import '../../widgets/refresh_error_banner.dart';
import '../../widgets/shimmer_loading.dart';
import '../github/github_contribution_graph.dart';
import '../home_widgets/home_widget_manager.dart';
import 'global_create_issue_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _mascotKey = GlobalKey();
  final _viewportKey = GlobalKey();
  bool _mascotVisible = false;
  bool _visibilityCheckScheduled = false;

  Future<void> _refreshDashboard() async {
    try {
      await ref.refresh(dashboardStatsProvider.future).then<void>((_) {});
    } catch (_) {
      // The retained dashboard shows an inline recovery message below.
    }
  }

  void _scheduleMascotVisibilityCheck() {
    if (_visibilityCheckScheduled) return;
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      if (!mounted) return;

      final mascotObject = _mascotKey.currentContext?.findRenderObject();
      final viewportObject = _viewportKey.currentContext?.findRenderObject();
      if (mascotObject is! RenderBox ||
          viewportObject is! RenderBox ||
          !mascotObject.hasSize ||
          !viewportObject.hasSize) {
        return;
      }

      final mascotRect =
          mascotObject.localToGlobal(Offset.zero) & mascotObject.size;
      final viewportRect =
          viewportObject.localToGlobal(Offset.zero) & viewportObject.size;
      final visiblePart = mascotRect.intersect(viewportRect);
      final area = mascotRect.width * mascotRect.height;
      final visible =
          area > 0 &&
          visiblePart.width > 0 &&
          visiblePart.height > 0 &&
          (visiblePart.width * visiblePart.height / area) >= 0.2;
      if (_mascotVisible != visible) {
        setState(() => _mascotVisible = visible);
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.sizeOf(context);
    MediaQuery.textScalerOf(context);
    _scheduleMascotVisibilityCheck();
  }

  String get _displayName {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final firstName = user?.userMetadata?['first_name'];
      if (firstName is String && firstName.trim().isNotEmpty) {
        return firstName.trim();
      }
      final fullName =
          user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'];
      if (fullName is String && fullName.trim().isNotEmpty) {
        return fullName.trim().split(' ').first;
      }
      final email = user?.email ?? '';
      if (email.contains('@')) {
        final prefix = email.split('@').first;
        final namePart = prefix.split('.').first.split('_').first;
        if (namePart.isNotEmpty) {
          return namePart[0].toUpperCase() + namePart.substring(1);
        }
        return prefix;
      }
    } catch (_) {
      // Supabase may not be initialized in test environments.
    }
    return 'Builder';
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

    ref.listen(dashboardStatsProvider, (_, next) {
      if (next.hasValue && next.value != null) {
        HomeWidgetManager.updateCompanionWidget(stats: next.value);
      }
    });

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
        onPressed: () => GlobalCreateIssueSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Capture'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
      ),
      body: statsAsync.when(
        skipLoadingOnRefresh: true,
        skipError: true,
        loading: () => const _DashboardSkeleton(),
        error: (error, _) => MakkoErrorState(
          message: _friendlyDashboardError(error),
          onRetry: () => unawaited(_refreshDashboard()),
        ),
        data: (stats) {
          _scheduleMascotVisibilityCheck();
          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.depth == 0 &&
                    notification.metrics.axis == Axis.vertical) {
                  _scheduleMascotVisibilityCheck();
                }
                return false;
              },
              child: ListView(
                key: _viewportKey,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (statsAsync.hasError)
                    RefreshErrorBanner(
                      message: 'Could not refresh dashboard data. Showing the last loaded view.',
                      onRetry: _refreshDashboard,
                    ),
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 20),
                  _MakkoCompanion(
                    stats: stats,
                    displayName: _displayName,
                    greeting: _greeting,
                    visible: _mascotVisible,
                    mascotKey: _mascotKey,
                  ),
                  const SizedBox(height: 20),
                  const AppSectionHeader(title: 'Workspace at a glance'),
                  const SizedBox(height: 10),
                  _MetricStrip(stats: stats),
                  const SizedBox(height: 22),
                  if (stats.projectCount == 0) ...[
                    const _EmptyWorkspaceCard(),
                    const SizedBox(height: 22),
                    const GithubContributionGraph(),
                  ] else ...[
                    _BreakdownSection(stats: stats),
                    if (stats.projects.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _WorkloadCard(stats: stats),
                    ],

                    const SizedBox(height: 22),
                    const GithubContributionGraph(),
                  ],
                  const SizedBox(height: 22),
                  _QuickActions(
                    onProjects: () => context.go('/projects'),
                    onNewProject: () => context.push('/projects/new'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MakkoCompanion extends StatefulWidget {
  final DashboardStats stats;
  final String displayName;
  final String greeting;
  final bool visible;
  final Key mascotKey;

  const _MakkoCompanion({
    required this.stats,
    required this.displayName,
    required this.greeting,
    required this.visible,
    required this.mascotKey,
  });

  @override
  State<_MakkoCompanion> createState() => _MakkoCompanionState();
}

class _MakkoCompanionState extends State<_MakkoCompanion> {
  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final scheme = Theme.of(context).colorScheme;
    final String message;

    if (stats.projectCount == 0) {
      message = 'Your workspace is ready for its first project.';
    } else if (stats.totalIssues == 0) {
      message = 'Your projects are set up. Add an internal task or bug when you’re ready.';
    } else if (stats.openIssues == 0 && stats.completedIssues > 0) {
      message = 'All internal issues are complete. Your workspace is clear.';
    } else {
      final itemWord = stats.openIssues == 1 ? 'open issue' : 'open issues';
      final projectWord = stats.projectCount == 1 ? 'project' : 'projects';
      message =
          '${stats.openIssues} $itemWord across ${stats.projectCount} $projectWord.';
    }

    return MakkoCard(
      borderRadius: MakkoShapes.radiusXl,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.greeting,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              MakkoMascot(
                key: widget.mascotKey,
                visible: widget.visible,
                width: 88,
                height: 68,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  final DashboardStats stats;

  const _MetricStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.makkoSemantics;

    return MakkoCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _MetricCell(
              label: 'Projects',
              value: '${stats.projectCount}',
              valueColor: scheme.onSurface,
            ),
          ),
          _MetricDivider(color: scheme.outlineVariant),
          Expanded(
            child: _MetricCell(
              label: 'Issues',
              value: '${stats.totalIssues}',
              valueColor: scheme.onSurface,
            ),
          ),
          _MetricDivider(color: scheme.outlineVariant),
          Expanded(
            child: _MetricCell(
              label: 'Open',
              value: '${stats.openIssues}',
              valueColor: scheme.primary,
            ),
          ),
          _MetricDivider(color: scheme.outlineVariant),
          Expanded(
            child: _MetricCell(
              label: 'Done',
              value: '${stats.completedIssues}',
              valueColor: semantics.done,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  final Color color;

  const _MetricDivider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 42, color: color.withValues(alpha: 0.65));
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  final DashboardStats stats;

  const _BreakdownSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final statusCard = _StatusBreakdownCard(stats: stats);
        final priorityCard = _PriorityBreakdownCard(stats: stats);

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: statusCard),
              const SizedBox(width: 14),
              Expanded(child: priorityCard),
            ],
          );
        }

        return Column(
          children: [statusCard, const SizedBox(height: 14), priorityCard],
        );
      },
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  final DashboardStats stats;

  const _StatusBreakdownCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final semantics = context.makkoSemantics;
    final scheme = Theme.of(context).colorScheme;
    final total = stats.totalIssues;

    final rows = [
      ('Todo', stats.byStatus['todo'] ?? 0, semantics.todo),
      ('In Progress', stats.byStatus['in_progress'] ?? 0, scheme.primary),
      ('Done', stats.byStatus['done'] ?? 0, semantics.done),
    ];

    return MakkoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Status',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final fraction = total > 0 ? (item.$2 / total) : 0.0;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < rows.length - 1 ? 12 : 0,
              ),
              child: _BreakdownRow(
                label: item.$1,
                count: item.$2,
                color: item.$3,
                fraction: fraction,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PriorityBreakdownCard extends StatelessWidget {
  final DashboardStats stats;

  const _PriorityBreakdownCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final semantics = context.makkoSemantics;
    final total = stats.totalIssues;

    final rows = [
      ('High', stats.byPriority['high'] ?? 0, semantics.high),
      ('Medium', stats.byPriority['medium'] ?? 0, semantics.medium),
      ('Low', stats.byPriority['low'] ?? 0, semantics.low),
    ];

    return MakkoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Priority',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final fraction = total > 0 ? (item.$2 / total) : 0.0;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < rows.length - 1 ? 12 : 0,
              ),
              child: _BreakdownRow(
                label: item.$1,
                count: item.$2,
                color: item.$3,
                fraction: fraction,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final double fraction;

  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.color,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _AnimatedProgressBar(
          fillKey: ValueKey(
            'dashboard-breakdown-fill-${label.toLowerCase().replaceAll(' ', '-')}',
          ),
          fraction: fraction,
          color: color,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
      ],
    );
  }
}

class _AnimatedProgressBar extends StatefulWidget {
  final Key? fillKey;
  final double fraction;
  final Color color;
  final Color backgroundColor;

  const _AnimatedProgressBar({
    this.fillKey,
    required this.fraction,
    required this.color,
    required this.backgroundColor,
  });

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    _reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    if (_reduceMotion) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fraction != widget.fraction) {
      if (_reduceMotion) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final clampedFraction = widget.fraction.clamp(0.0, 1.0);
        return Container(
          height: 6,
          width: totalWidth,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(MakkoShapes.radiusFull),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final currentFraction = _reduceMotion
                    ? clampedFraction
                    : clampedFraction * _animation.value;
                return Container(
                  key: widget.fillKey,
                  width: totalWidth * currentFraction,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(MakkoShapes.radiusFull),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  final DashboardStats stats;

  const _WorkloadCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.makkoSemantics;

    return MakkoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Project workload',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stats.projects.length} ${stats.projects.length == 1 ? 'project' : 'projects'}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...stats.projects.take(6).map((project) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(MakkoShapes.radius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(MakkoShapes.radius),
                  onTap: () => context.push('/projects/${project.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                project.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _CountPill(
                              label: '${project.open} open',
                              color: scheme.primary,
                            ),
                            _CountPill(
                              label: '${project.completed} done',
                              color: semantics.done,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

class _EmptyWorkspaceCard extends StatelessWidget {
  const _EmptyWorkspaceCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MakkoCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 28,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your workspace is empty',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first project to start tracking',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/projects/new'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create project'),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final stackActions = constraints.maxWidth < 360 || textScale >= 1.2;
      final projectsButton = OutlinedButton.icon(
        onPressed: onProjects,
        icon: const Icon(Icons.folder_open_rounded, size: 18),
        label: const Text('View projects'),
      );
      final newProjectButton = FilledButton.icon(
        onPressed: onNewProject,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('New project'),
      );

      if (stackActions) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            projectsButton,
            const SizedBox(height: 8),
            newProjectButton,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: projectsButton),
          const SizedBox(width: 10),
          Expanded(child: newProjectButton),
        ],
      );
    },
  );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ShimmerContainer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const ShimmerBox(width: 160, height: 26),
          const SizedBox(height: 8),
          const ShimmerBox(width: 240, height: 16),
          const SizedBox(height: 20),

          // Companion placeholder
          MakkoCard(
            borderRadius: MakkoShapes.radiusXl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const ShimmerBox(
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerBox(width: 140, height: 16),
                          const SizedBox(height: 8),
                          ShimmerBox(
                            width: 80,
                            height: 20,
                            borderRadius: BorderRadius.circular(
                              MakkoShapes.radiusFull,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const ShimmerBox(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                const ShimmerBox(width: 220, height: 14),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    12,
                    (i) => Expanded(
                      child: Container(
                        height: 8,
                        margin: EdgeInsets.only(right: i < 11 ? 4 : 0),
                        child: ShimmerBox(
                          height: 8,
                          borderRadius: BorderRadius.circular(
                            MakkoShapes.radiusFull,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const ShimmerBox(width: 160, height: 18),
          const SizedBox(height: 10),

          // Metric strip placeholder
          MakkoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 70, height: 14),
                            SizedBox(height: 8),
                            ShimmerBox(width: 40, height: 28),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 74,
                      color: scheme.outlineVariant,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 70, height: 14),
                            SizedBox(height: 8),
                            ShimmerBox(width: 40, height: 28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, color: scheme.outlineVariant),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 60, height: 14),
                            SizedBox(height: 8),
                            ShimmerBox(width: 40, height: 28),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 74,
                      color: scheme.outlineVariant,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 80, height: 14),
                            SizedBox(height: 8),
                            ShimmerBox(width: 40, height: 28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          MakkoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 90, height: 18),
                const SizedBox(height: 14),
                for (var i = 0; i < 3; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 80, height: 14),
                      ShimmerBox(width: 24, height: 14),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ShimmerBox(
                    width: double.infinity,
                    height: 6,
                    borderRadius: BorderRadius.circular(MakkoShapes.radiusFull),
                  ),
                  if (i < 2) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyDashboardError(Object error) {
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  return message.isEmpty || message.contains('Instance of')
      ? 'Check your connection and try again.'
      : message;
}
