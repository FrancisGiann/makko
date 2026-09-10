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
  List<String> _tags = [];
  bool _isLoading = false;
  bool _seeded = false;
  String? _error;

  String _initialName = '';
  String _initialDescription = '';
  List<String> _initialTags = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _seed(Project project) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = project.name;
    _descriptionController.text = project.description ?? '';
    _tags = List<String>.from(project.tags);
    _initialName = project.name;
    _initialDescription = project.description ?? '';
    _initialTags = List<String>.from(project.tags);
  }

  bool get _isDirty {
    if (_nameController.text.trim() != _initialName.trim()) return true;
    if (_descriptionController.text.trim() != _initialDescription.trim()) {
      return true;
    }
    if (_tags.length != _initialTags.length) return true;
    for (var i = 0; i < _tags.length; i++) {
      if (_tags[i] != _initialTags[i]) return true;
    }
    return false;
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final unique = <String>{};
    if (_tags.length > 20 ||
        _tags.any((tag) => tag.length > 40) ||
        _tags.any((tag) => !unique.add(tag.toLowerCase()))) {
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
          tags: _tags,
        );
      } else {
        await notifier.updateProject(
          widget.projectId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          tags: _tags,
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

    return PopScope(
      canPop: !_isDirty || _isLoading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit project' : 'New project'),
          leading: IconButton(
            tooltip: 'Close',
            onPressed: () async {
              if (_isDirty && !_isLoading) {
                final discard = await _confirmDiscard();
                if (discard && context.mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
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
                    message:
                        'This project could not be loaded. Go back and try again.',
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
                _TagInput(
                  tags: _tags,
                  enabled: !_isLoading,
                  onChanged: (tags) => setState(() => _tags = tags),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tags stay private to your workspace.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
      ),
    );
  }
}

class _TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const _TagInput({
    required this.tags,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<_TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<_TagInput> {
  final _controller = TextEditingController();
  String? _tagError;

  void _addTag() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    if (widget.tags.length >= 20) {
      setState(() => _tagError = 'Maximum 20 tags allowed.');
      return;
    }
    if (raw.length > 40) {
      setState(() => _tagError = 'Tag must be 40 characters or fewer.');
      return;
    }
    if (widget.tags.any((t) => t.toLowerCase() == raw.toLowerCase())) {
      setState(() => _tagError = 'Tag already added.');
      return;
    }
    final next = List<String>.from(widget.tags)..add(raw);
    _controller.clear();
    setState(() => _tagError = null);
    widget.onChanged(next);
  }

  void _removeTag(int index) {
    final next = List<String>.from(widget.tags)..removeAt(index);
    setState(() => _tagError = null);
    widget.onChanged(next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          onFieldSubmitted: (_) => _addTag(),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Add tag',
            hintText: 'e.g. mobile, frontend, mvp',
            errorText: _tagError,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add tag',
              onPressed: widget.enabled ? _addTag : null,
            ),
          ),
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (var i = 0; i < widget.tags.length; i++)
                InputChip(
                  label: Text(widget.tags[i]),
                  onDeleted: widget.enabled ? () => _removeTag(i) : null,
                  deleteIconColor: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ],
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
