import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/github_commit.dart';
import '../../models/github_issue.dart';
import '../../providers/github_provider.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/error_state.dart';
import '../../widgets/makko_card.dart';
import '../../widgets/refresh_error_banner.dart';
import 'github_connection_sheet.dart';

class GithubSection extends ConsumerWidget {
  final String projectId;
  const GithubSection({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(githubProvider(projectId));
    final action = ref.watch(githubNotifierProvider);

    Future<void> retryData() async {
      try {
        await ref.refresh(githubProvider(projectId).future).then<void>((_) {});
      } catch (_) {
        // If a repository was previously loaded, its data remains available.
      }
    }

    return dataAsync.when(
      skipLoadingOnRefresh: true,
      skipError: true,
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => MakkoErrorState(
        message: 'Unable to load GitHub activity.',
        onRetry: () => retryData(),
      ),
      data: (data) {
        if (data.link == null) return _ConnectCard(projectId: projectId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dataAsync.hasError)
              RefreshErrorBanner(
                message: 'Could not refresh GitHub activity. Showing the last loaded data.',
                onRetry: retryData,
              ),
            AppSectionHeader(
              title: 'GitHub',
              subtitle: 'Read-only code context',
              trailing: PopupMenuButton<String>(
                tooltip: 'GitHub actions',
                onSelected: (value) {
                  if (value == 'sync') _sync(context, ref);
                  if (value == 'disconnect')
                    _confirmDisconnect(context, ref, data.link!.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'sync', child: Text('Sync now')),
                  PopupMenuItem(value: 'disconnect', child: Text('Disconnect')),
                ],
              ),
            ),
            const SizedBox(height: 10),
            MakkoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.code_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openExternal(
                            context,
                            'https://github.com/${data.link!.repoFullName}',
                          ),
                          borderRadius: BorderRadius.circular(
                            MakkoShapes.radiusSm,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              data.link!.repoFullName,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: action.isLoading
                            ? null
                            : () => _sync(context, ref),
                        child: action.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sync now'),
                      ),
                    ],
                  ),
                  if (data.link!.lastSyncedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _SyncStatus(lastSyncedAt: data.link!.lastSyncedAt),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: _SyncStatus(lastSyncedAt: null),
                    ),
                  if (data.commits.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Recent commits',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...data.commits.map((commit) => _CommitRow(commit: commit)),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Text('No commits synced yet.'),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Open GitHub issues',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (data.issues.isEmpty)
                    const Text('No open GitHub issues.')
                  else
                    ...data.issues.map(
                      (issue) => _GithubIssueRow(issue: issue),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'External GitHub issues are read-only and never change Makko dashboard totals.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (action.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'GitHub action failed. Try again in a moment.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(githubNotifierProvider.notifier).syncGithub(projectId);
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GitHub activity synced.')),
        );
    } catch (_) {
      /* surfaced through provider state */
    }
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    WidgetRef ref,
    String linkId,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Disconnect repository?'),
            content: const Text(
              'Cached GitHub commits and issues for this project will be removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(githubNotifierProvider.notifier)
          .disconnect(projectId, linkId);
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repository disconnected.')),
        );
    } catch (_) {
      /* surfaced through provider state */
    }
  }
}

class _ConnectCard extends StatelessWidget {
  final String projectId;
  const _ConnectCard({required this.projectId});
  @override
  Widget build(BuildContext context) => MakkoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'GitHub',
          subtitle: 'Read-only code context',
        ),
        const SizedBox(height: 12),
        Text(
          'Connect a repository to see recent commits and open issues beside your internal work.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GithubConnectionSheet(projectId: projectId),
            ),
          ),
          icon: const Icon(Icons.link_rounded),
          label: const Text('Connect repository'),
        ),
      ],
    ),
  );
}

class _SyncStatus extends StatelessWidget {
  final DateTime? lastSyncedAt;
  const _SyncStatus({required this.lastSyncedAt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stale =
        lastSyncedAt != null &&
        DateTime.now().difference(lastSyncedAt!).inHours >= 24;
    final color = stale
        ? context.makkoSemantics.medium
        : lastSyncedAt == null
        ? scheme.onSurfaceVariant
        : context.makkoSemantics.done;
    final label = stale
        ? 'Sync needs attention'
        : lastSyncedAt == null
        ? 'Not synced yet'
        : 'Sync healthy';
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          stale
              ? Icons.warning_amber_rounded
              : lastSyncedAt == null
              ? Icons.schedule_outlined
              : Icons.verified_outlined,
          size: 17,
          color: color,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color),
        ),
        Text(
          lastSyncedAt == null
              ? 'Sync this repository to load fresh data.'
              : 'Last synced ${_relative(lastSyncedAt!)}',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CommitRow extends StatelessWidget {
  final GithubCommit commit;
  const _CommitRow({required this.commit});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _openExternal(context, commit.htmlUrl),
    borderRadius: BorderRadius.circular(MakkoShapes.radius),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(MakkoShapes.radiusSm),
            ),
            child: Text(
              commit.sha.length > 7 ? commit.sha.substring(0, 7) : commit.sha,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit.message.split('\n').first,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${commit.authorName.isEmpty ? 'Unknown author' : commit.authorName} · ${_relative(commit.date)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, size: 17),
        ],
      ),
    ),
  );
}

class _GithubIssueRow extends StatelessWidget {
  final GithubIssue issue;
  const _GithubIssueRow({required this.issue});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _openExternal(context, issue.url),
      borderRadius: BorderRadius.circular(MakkoShapes.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${issue.number}',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: scheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (issue.labels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        issue.labels.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 17),
          ],
        ),
      ),
    );
  }
}

Future<void> _openExternal(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.toLowerCase() != 'github.com') {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This GitHub link is not available.')),
      );
    return;
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
      context.mounted)
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Could not open GitHub.')));
}

String _relative(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}
