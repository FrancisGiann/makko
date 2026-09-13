with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Update the AppBar to remove the title (since it's moving to the card)
target_appbar = """        appBar: AppBar(
          title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: ["""

replacement_appbar = """        appBar: AppBar(
          title: const Text('Project Details'),
          centerTitle: true,
          actions: ["""

if target_appbar in content:
    content = content.replace(target_appbar, replacement_appbar)
else:
    print("Could not find AppBar target")

# 2. Rewrite _CompactProjectMetaCard
target_card = """class _CompactProjectMetaCard extends StatelessWidget {
  final Project project;
  final Map<String, int> counts;

  const _CompactProjectMetaCard({
    required this.project,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.makkoSemantics;

    final hasDescription = project.description?.trim().isNotEmpty == true;
    final hasTags = project.tags.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDescription) ...[
            Text(
              project.description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (hasTags) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: project.tags.map((tag) => TagChip(tag: tag)).toList(),
            ),
            const SizedBox(height: 8),
          ],
          // Status summary counts with colored dots
          Row(
            children: [
              _StatusDotCount(
                label: 'To do',
                count: counts['todo'] ?? 0,
                color: semantics.todo,
              ),
              const SizedBox(width: 14),
              _StatusDotCount(
                label: 'In progress',
                count: counts['in_progress'] ?? 0,
                color: scheme.primary,
              ),
              const SizedBox(width: 14),
              _StatusDotCount(
                label: 'Done',
                count: counts['done'] ?? 0,
                color: semantics.done,
              ),
            ],
          ),
        ],
      ),
    );
  }
}"""

replacement_card = """class _CompactProjectMetaCard extends StatelessWidget {
  final Project project;
  final Map<String, int> counts;

  const _CompactProjectMetaCard({
    required this.project,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.makkoSemantics;

    final hasDescription = project.description?.trim().isNotEmpty == true;
    final hasTags = project.tags.isNotEmpty;

    return MakkoCard(
      padding: const EdgeInsets.all(20),
      borderRadius: MakkoShapes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            project.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          if (hasDescription) ...[
            const SizedBox(height: 8),
            Text(
              project.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (hasTags) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.tags.map((tag) => TagChip(tag: tag)).toList(),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Status summary counts with colored dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusDotCount(
                label: 'To do',
                count: counts['todo'] ?? 0,
                color: semantics.todo,
              ),
              _StatusDotCount(
                label: 'In progress',
                count: counts['in_progress'] ?? 0,
                color: scheme.primary,
              ),
              _StatusDotCount(
                label: 'Done',
                count: counts['done'] ?? 0,
                color: semantics.done,
              ),
            ],
          ),
        ],
      ),
    );
  }
}"""

if target_card in content:
    content = content.replace(target_card, replacement_card)
    print("Replaced _CompactProjectMetaCard successfully.")
else:
    print("Could not find _CompactProjectMetaCard target.")
    
with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
    f.write(content)

