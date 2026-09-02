import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/project.dart';
import '../../providers/projects_provider.dart';
import '../../services/validation.dart';

/// Full-screen project editor. The historical class name is retained so
/// callers/tests do not need a migration.
class CreateProjectSheet extends ConsumerStatefulWidget {
  final String? projectId;
  const CreateProjectSheet({super.key, this.projectId});
  bool get isEditing => projectId != null;

  @override
  ConsumerState<CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends ConsumerState<CreateProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isLoading = false;
  bool _seeded = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _seed(Project project) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = project.name;
    _descriptionController.text = project.description ?? '';
    _tagsController.text = project.tags.join(', ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final unique = <String>{};
    if (tags.length > 20 ||
        tags.any((tag) => tag.length > 40) ||
        tags.any((tag) => !unique.add(tag.toLowerCase()))) {
      setState(
        () => _error = 'Use up to 20 unique tags, each 40 characters or fewer.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(projectsProvider.notifier);
      if (widget.projectId == null) {
        await notifier.createProject(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          tags: tags,
        );
      } else {
        await notifier.updateProject(
          widget.projectId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          tags: tags,
        );
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted)
        setState(
          () => _error = _friendlyError(
            error,
            widget.isEditing
                ? 'Unable to update this project.'
                : 'Unable to create this project.',
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    if (widget.projectId != null) {
      final matches =
          projects.valueOrNull
              ?.where((project) => project.id == widget.projectId)
              .toList() ??
          const <Project>[];
      final match = matches.isEmpty ? null : matches.first;
      if (match != null) _seed(match);
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit project' : 'New project'),
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
              if (widget.projectId != null && projects.isLoading && !_seeded)
                const LinearProgressIndicator(),
              if (widget.projectId != null && projects.hasError)
                _InlineError(
                  message: 'This project could not be loaded. Go back and try again.',
                ),
              Text(
                'Keep the context close',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                widget.isEditing
                    ? 'Refine the project details and tags.'
                    : 'Give the next piece of work a home.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                validator: Validation.validateName,
                decoration: const InputDecoration(
                  labelText: 'Project name',
                  hintText: 'e.g. Weekend compiler',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 3,
                validator: (value) => (value?.trim().length ?? 0) > 5000
                    ? 'Description must be 5,000 characters or fewer'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What are you building?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                textCapitalization: TextCapitalization.none,
                validator: (value) =>
                    (value
                                ?.split(',')
                                .where((tag) => tag.trim().isNotEmpty)
                                .length ??
                            0) >
                        20
                    ? 'Use up to 20 tags'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'flutter, shipped, client (comma separated)',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tags stay private to your workspace.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _InlineError(message: _error!),
                ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : Icon(
                        widget.isEditing
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                      ),
                label: _isLoading
                    ? const _ProgressLabel()
                    : Text(
                        widget.isEditing ? 'Save changes' : 'Create project',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(MakkoShapes.radius),
    ),
    child: Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel();
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
      const Text('Saving…'),
    ],
  );
}

String _friendlyError(Object error, String fallback) {
  final message = error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('ValidationError: ', '')
      .trim();
  return message.isEmpty || message.contains('Instance of')
      ? fallback
      : message;
}
