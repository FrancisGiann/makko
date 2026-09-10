import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/github_provider.dart';
import '../../services/validation.dart';

class GithubConnectionSheet extends ConsumerStatefulWidget {
  final String projectId;
  const GithubConnectionSheet({super.key, required this.projectId});
  @override
  ConsumerState<GithubConnectionSheet> createState() =>
      _GithubConnectionSheetState();
}

class _GithubConnectionSheetState extends ConsumerState<GithubConnectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repoController = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _repoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final parts = _repoController.text.trim().split('/');
    setState(() => _error = null);
    try {
      await ref
          .read(githubNotifierProvider.notifier)
          .connect(widget.projectId, parts[0], parts[1]);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyGithubError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(githubNotifierProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect GitHub'),
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Bring code context alongside your project.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Makko only reads synchronized commits and open issues.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _repoController,
                textCapitalization: TextCapitalization.none,
                validator: Validation.validateRepository,
                decoration: const InputDecoration(
                  labelText: 'Repository',
                  hintText: 'owner/repository',
                  prefixIcon: Icon(Icons.code_rounded),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(MakkoShapes.radius),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No personal access token is needed. The secure Edge Function handles GitHub synchronization.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: TextStyle(color: scheme.error)),
                ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: state.isLoading ? null : _submit,
                icon: state.isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.link_rounded),
                label: state.isLoading
                    ? const _ConnectProgress()
                    : const Text('Connect repository'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectProgress extends StatelessWidget {
  const _ConnectProgress();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      const SizedBox(width: 10),
      const Text('Connecting…'),
    ],
  );
}

String _friendlyGithubError(Object error) {
  final text = error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('FormatException: ', '')
      .trim();
  return text.isEmpty || text.contains('Instance of')
      ? 'Unable to connect this repository. Try again.'
      : text;
}
