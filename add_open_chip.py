with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()

target = """          _ChipGroup(
            label: 'Status',
            children: [
              FilterChip(
                label: const Text('All'),
                selected: filters.status == 'all',
                onSelected: (selected) {
                  if (selected) onFilterChanged(status: 'all');
                },
              ),"""

replacement = """          _ChipGroup(
            label: 'Status',
            children: [
              FilterChip(
                label: const Text('Open'),
                selected: filters.status == 'open',
                onSelected: (selected) {
                  if (selected) onFilterChanged(status: 'open');
                },
              ),
              FilterChip(
                label: const Text('All'),
                selected: filters.status == 'all',
                onSelected: (selected) {
                  if (selected) onFilterChanged(status: 'all');
                },
              ),"""

# also need to update the fallback from 'all' to 'open' if unselecting a status
content = content.replace("onFilterChanged(status: selected ? 'todo' : 'all');", "onFilterChanged(status: selected ? 'todo' : 'open');")
content = content.replace("onFilterChanged(status: selected ? 'in_progress' : 'all');", "onFilterChanged(status: selected ? 'in_progress' : 'open');")
content = content.replace("onFilterChanged(status: selected ? 'done' : 'all');", "onFilterChanged(status: selected ? 'done' : 'open');")

if target in content:
    content = content.replace(target, replacement)
    with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
        f.write(content)
    print("Added Open chip")
else:
    print("Could not find target chip group")
