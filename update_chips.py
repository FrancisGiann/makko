with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()

target = """          // Status Chips
          ChoiceChip(
            label: const Text('All status'),
            selected: filters.status == 'all',
            onSelected: (selected) {
              if (selected) onFilterChanged(status: 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Todo'),
            selected: filters.status == 'todo',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'todo' : 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('In Progress'),
            selected: filters.status == 'in_progress',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'in_progress' : 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Done'),
            selected: filters.status == 'done',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'done' : 'all');
            },
          ),"""

replacement = """          // Status Chips
          ChoiceChip(
            label: const Text('Open'),
            selected: filters.status == 'open',
            onSelected: (selected) {
              if (selected) onFilterChanged(status: 'open');
            },
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('All'),
            selected: filters.status == 'all',
            onSelected: (selected) {
              if (selected) onFilterChanged(status: 'all');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Todo'),
            selected: filters.status == 'todo',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'todo' : 'open');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('In Progress'),
            selected: filters.status == 'in_progress',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'in_progress' : 'open');
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Done'),
            selected: filters.status == 'done',
            onSelected: (selected) {
              onFilterChanged(status: selected ? 'done' : 'open');
            },
          ),"""

content = content.replace(target, replacement)

with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
    f.write(content)
print("Updated chips.")
