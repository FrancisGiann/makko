import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/project.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/issues_provider.dart';
import '../../providers/projects_provider.dart';
import '../../services/validation.dart';

class GlobalCreateIssueSheet extends ConsumerStatefulWidget {
  const GlobalCreateIssueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MakkoShapes.radiusXl),
        ),
      ),
      builder: (_) => const GlobalCreateIssueSheet(),
    );
  }

  @override
  ConsumerState<GlobalCreateIssueSheet> createState() =>
      _GlobalCreateIssueSheetState();
}

class _GlobalCreateIssueSheetState
    extends ConsumerState<GlobalCreateIssueSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedProjectId;
  String _type = 'task';
  String _priority = 'medium';
  String _status = 'todo';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Project> projects) async {
    final projectId = _selectedProjectId ?? (projects.isNotEmpty ? projects.first.id : null);
    if (projectId == null) {
      setState(() => _error = 'Please select a project for this issue.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      HapticFeedback.lightImpact();
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      await ref.read(issuesProvider(projectId).notifier).createIssue(
            title: title,
            description: description.isEmpty ? null : description,
            type: _type,
            priority: _priority,
            status: _status,
          );

      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(issueStatusCountsProvider(projectId));

      if (mounted) {
        Navigator.of(context).pop();
        final projectName = projects.firstWhere(
          (p) => p.id == projectId,
          orElse: () => Project(
            id: projectId,
            ownerId: '',
            name: 'project',
            tags: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ).name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue captured into $projectName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('ValidationError: ', '')
              .trim(),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final projectsAsync = ref.watch(projectsProvider);
    final projects = projectsAsync.valueOrNull ?? const [];

    if (projects.isNotEmpty && _selectedProjectId == null) {
      _selectedProjectId = projects.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(MakkoShapes.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(MakkoShapes.radius),
                          ),
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 20,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Quick Capture',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Quickly file a task or bug into any of your projects.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),

                // Projects loading / empty / dropdown
                if (projectsAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (projects.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(MakkoShapes.radius),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'No projects available yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/projects/new');
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create a project first'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Project Selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      prefixIcon: Icon(Icons.folder_outlined, size: 20),
                    ),
                    items: projects.map((project) {
                      return DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedProjectId = val);
                            }
                          },
                  ),
                  const SizedBox(height: 16),

                  // Issue Title
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    validator: Validation.validateIssueTitle,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'What needs attention?',
                      prefixIcon: Icon(Icons.edit_note_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description (Optional)
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    validator: (value) =>
                        (value?.trim().length ?? 0) > 10000
                            ? 'Description must be 10,000 characters or fewer'
                            : null,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Add context or reproduction steps…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Type SegmentedButton
                  Text(
                    'Type',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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
                      onSelectionChanged: _isLoading
                          ? null
                          : (s) => setState(() => _type = s.first),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Priority SegmentedButton
                  Text(
                    'Priority',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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
                      onSelectionChanged: _isLoading
                          ? null
                          : (s) => setState(() => _priority = s.first),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Status SegmentedButton
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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
                      onSelectionChanged: _isLoading
                          ? null
                          : (s) => setState(() => _status = s.first),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius:
                            BorderRadius.circular(MakkoShapes.radius),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: scheme.onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: scheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Capture Action Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : () => _submit(projects),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_rounded, size: 20),
                      label: Text(_isLoading ? 'Capturing…' : 'Capture issue'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
