import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/issue.dart';
import '../../providers/issues_provider.dart';
import '../../services/issue_service.dart';
import '../../services/validation.dart';

class CreateIssueSheet extends ConsumerStatefulWidget {
  final String projectId;
  final String? issueId;
  const CreateIssueSheet({super.key, required this.projectId, this.issueId});
  bool get isEditing => issueId != null;

  @override
  ConsumerState<CreateIssueSheet> createState() => _CreateIssueSheetState();
}

class _CreateIssueSheetState extends ConsumerState<CreateIssueSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'task';
  String _priority = 'medium';
  String _status = 'todo';
  bool _isLoading = false;
  bool _seeded = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _seedLoadedIssue(Issue issue) {
    if (_seeded || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _seeded) return;
      setState(() {
        _seeded = true;
        _titleController.text = issue.title;
        _descriptionController.text = issue.description ?? '';
        _type = issue.type;
        _priority = issue.priority;
        _status = issue.status;
      });
    });
  }

  Future<void> _submit() async {
    if (widget.isEditing && !_seeded) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(issuesProvider(widget.projectId).notifier);
      if (widget.issueId == null) {
        await notifier.createIssue(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          type: _type,
          priority: _priority,
          status: _status,
        );
      } else {
        await notifier.updateIssue(
          issueId: widget.issueId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          type: _type,
          priority: _priority,
          status: _status,
        );
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted)
        setState(
          () => _error = _friendlyIssueError(
            error,
            widget.isEditing
                ? 'Unable to update this issue.'
                : 'Unable to create this issue.',
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = widget.issueId == null
        ? null
        : IssueLookup(projectId: widget.projectId, issueId: widget.issueId!);
    final issueAsync = lookup == null ? null : ref.watch(issueProvider(lookup));
    if (lookup != null) {
      ref.listen<AsyncValue<Issue?>>(issueProvider(lookup), (_, next) {
        final issue = next.valueOrNull;
        if (issue != null) _seedLoadedIssue(issue);
      });
      final loadedIssue = issueAsync?.valueOrNull;
      if (loadedIssue != null) _seedLoadedIssue(loadedIssue);
    }
    final editReady =
        !widget.isEditing ||
        (issueAsync?.hasValue == true && issueAsync?.valueOrNull != null);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit issue' : 'New issue'),
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
                widget.isEditing
                    ? 'Keep the signal clear'
                    : 'Capture the next piece of work',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Internal Makko issues stay separate from read-only GitHub activity.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (widget.isEditing && issueAsync!.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),
              if (widget.isEditing && issueAsync!.hasError)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _InlineIssueError(
                    message: 'Unable to load this issue. Close and try again.',
                  ),
                ),
              if (widget.isEditing &&
                  issueAsync!.hasValue &&
                  issueAsync.valueOrNull == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _InlineIssueError(
                    message: 'This issue no longer exists or is unavailable.',
                  ),
                ),
              TextFormField(
                controller: _titleController,
                enabled: editReady && !_isLoading,
                textCapitalization: TextCapitalization.sentences,
                validator: Validation.validateIssueTitle,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs attention?',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: editReady && !_isLoading,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 3,
                validator: (value) => (value?.trim().length ?? 0) > 10000
                    ? 'Description must be 10,000 characters or fewer'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add useful context (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(label: 'Type'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'task',
                      label: Text('Task'),
                      icon: Icon(Icons.check_circle_outline, size: 18),
                    ),
                    ButtonSegment(
                      value: 'bug',
                      label: Text('Bug'),
                      icon: Icon(Icons.bug_report_outlined, size: 18),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: editReady && !_isLoading
                      ? (newSelection) =>
                          setState(() => _type = newSelection.first)
                      : null,
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(label: 'Priority'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'low', label: Text('Low')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'high', label: Text('High')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: editReady && !_isLoading
                      ? (newSelection) =>
                          setState(() => _priority = newSelection.first)
                      : null,
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(label: 'Status'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'todo', label: Text('To do')),
                    ButtonSegment(
                      value: 'in_progress',
                      label: Text('In progress'),
                    ),
                    ButtonSegment(value: 'done', label: Text('Done')),
                  ],
                  selected: {_status},
                  onSelectionChanged: editReady && !_isLoading
                      ? (newSelection) =>
                          setState(() => _status = newSelection.first)
                      : null,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _InlineIssueError(message: _error!),
                ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isLoading || !editReady ? null : _submit,
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : Icon(
                        widget.isEditing
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                      ),
                label: _isLoading
                    ? const _IssueProgress()
                    : Text(widget.isEditing ? 'Save changes' : 'Create issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InlineIssueError extends StatelessWidget {
  final String message;
  const _InlineIssueError({required this.message});
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

class _IssueProgress extends StatelessWidget {
  const _IssueProgress();
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

String _friendlyIssueError(Object error, String fallback) {
  final message = error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('ValidationError: ', '')
      .trim();
  return message.isEmpty || message.contains('Instance of')
      ? fallback
      : message;
}
